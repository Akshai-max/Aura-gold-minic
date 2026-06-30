import time
import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import Optional

from app.core import audit_actions
from app.core.config import settings
from app.core.exceptions import ForbiddenException, ValidationException
from app.core.permissions import user_has_permission
from app.models.user import User
from app.repositories.app_metrics import AppMetricsRepository
from app.repositories.digital_metal_inventory import DigitalMetalInventoryRepository
from app.repositories.report import ReportRepository
from app.schemas.digital_metal_inventory import compute_stock_status
from app.schemas.report import (
    AnalyticsOverviewResponse,
    AuditBreakdownRow,
    AuditReportResponse,
    CustomerReportResponse,
    CustomerTypeRow,
    ExportFormat,
    InventoryCategoryRow,
    InventoryReportResponse,
    InventoryTrendPoint,
    KpiCard,
    ActivityTrendPoint,
    MetalStockRow,
    MetricMethodology,
    ReportType,
    RevenueReportResponse,
    RevenueTrendPoint,
    TransactionBreakdownRow,
    TransactionReportResponse,
)
from app.services.audit import AuditService
from app.services.metal_prices import MetalPriceService
from app.utils.report_export import (
    MEDIA_TYPES,
    export_filename,
    rows_to_csv,
    rows_to_pdf,
    rows_to_xlsx,
)

_cache: dict[str, tuple[float, AnalyticsOverviewResponse]] = {}

_APP_REVENUE_METHODOLOGY = [
    MetricMethodology(
        key="total_revenue",
        title="Total App Revenue",
        formula="SUM(amount_paise) ÷ 100 for payment_orders where status = paid",
        data_source="payment_orders (Razorpay gold/silver purchases)",
    ),
    MetricMethodology(
        key="daily_revenue",
        title="Daily Revenue",
        formula="Paid order revenue where paid_at (or created_at) is today (UTC)",
        data_source="payment_orders",
    ),
    MetricMethodology(
        key="monthly_revenue",
        title="Monthly Revenue",
        formula="Paid order revenue from the 1st of this month through today",
        data_source="payment_orders",
    ),
]

_METAL_INVENTORY_METHODOLOGY = [
    MetricMethodology(
        key="metal_inventory_value",
        title="Metal Inventory Value",
        formula="Σ (available grams × current retail rate per gram) for gold and silver",
        data_source="digital_metal_inventory + live metal prices",
    ),
]


class ReportService:
    """Reports and analytics aggregation with export support."""

    def __init__(
        self,
        report_repo: ReportRepository,
        app_metrics_repo: AppMetricsRepository,
        digital_inventory_repo: DigitalMetalInventoryRepository,
        metal_price_service: MetalPriceService,
        audit_service: Optional[AuditService] = None,
    ):
        self.report_repo = report_repo
        self.app_metrics_repo = app_metrics_repo
        self.digital_inventory_repo = digital_inventory_repo
        self.metal_price_service = metal_price_service
        self.audit_service = audit_service

    async def _digital_metal_summary(self) -> tuple[Decimal, list[MetalStockRow], int]:
        metals = await self.digital_inventory_repo.list_all()
        prices = await self.metal_price_service.get_prices()
        price_by_metal = {
            "gold": prices.gold.retail_price,
            "silver": prices.silver.retail_price,
        }
        total_value = Decimal("0")
        rows: list[MetalStockRow] = []
        low_stock_count = 0
        for row in metals:
            available = row.available_weight_grams
            rate = price_by_metal.get(row.metal_type, Decimal("0"))
            value = available * rate
            total_value += value
            rows.append(
                MetalStockRow(
                    metal_type=row.metal_type.upper(),
                    available_grams=available,
                    rate_per_gram=rate,
                    value_inr=value,
                )
            )
            status = compute_stock_status(available, row.low_stock_threshold_grams)
            if status in {"low_stock", "out_of_stock"}:
                low_stock_count += 1
        return total_value, rows, low_stock_count

    def _require(self, user: User, permission: str) -> None:
        if not user_has_permission(user, permission):
            raise ForbiddenException(f"You do not have permission: {permission}")

    def _default_period(
        self, start: Optional[datetime], end: Optional[datetime], days: int = 30
    ) -> tuple[datetime, datetime]:
        end_dt = end or datetime.now(timezone.utc)
        start_dt = start or (end_dt - timedelta(days=days))
        return start_dt, end_dt

    async def get_analytics_overview(self, user: User) -> AnalyticsOverviewResponse:
        cache_key = str(user.id)
        now = time.monotonic()
        cached = _cache.get(cache_key)
        if cached and (now - cached[0]) < settings.REPORT_ANALYTICS_CACHE_TTL_SECONDS:
            return cached[1]

        kpis: list[KpiCard] = []
        revenue_trend: list[RevenueTrendPoint] = []
        inventory_trend: list[InventoryTrendPoint] = []
        revenue_growth = None
        methodology: list[MetricMethodology] = []
        daily_revenue = None
        monthly_revenue = None
        total_revenue = None
        metal_inventory_value = None

        can_view_app = user_has_permission(user, "transaction.view") or user_has_permission(
            user, "wallet.view"
        )

        if can_view_app:
            now_dt = datetime.now(timezone.utc)
            day_start = now_dt.replace(hour=0, minute=0, second=0, microsecond=0)
            day_end = day_start.replace(
                hour=23, minute=59, second=59, microsecond=999999
            )
            month_start = day_start.replace(day=1)

            daily = await self.app_metrics_repo.paid_revenue_period_summary(
                start=day_start, end=day_end
            )
            monthly = await self.app_metrics_repo.paid_revenue_period_summary(
                start=month_start, end=day_end
            )
            total_revenue = await self.app_metrics_repo.paid_revenue_sum()
            daily_revenue = daily["total_revenue"]
            monthly_revenue = monthly["total_revenue"]
            revenue_growth = await self.app_metrics_repo.payment_revenue_growth_percent()
            trend_rows = await self.app_metrics_repo.payment_revenue_trend(days=30)
            revenue_trend = [
                RevenueTrendPoint(
                    label=r["label"],
                    revenue=r["revenue"],
                    transaction_count=r["transaction_count"],
                )
                for r in trend_rows
            ]
            methodology.extend(_APP_REVENUE_METHODOLOGY)
            kpis.extend(
                [
                    KpiCard(
                        key="daily_revenue",
                        label="Daily App Revenue",
                        value=f"₹{daily['total_revenue']:,.0f}",
                        trend_label=f"{daily['transaction_count']} paid buys today",
                        trend_positive=True,
                    ),
                    KpiCard(
                        key="monthly_revenue",
                        label="Monthly App Revenue",
                        value=f"₹{monthly['total_revenue']:,.0f}",
                        trend_label=f"{monthly['transaction_count']} paid buys this month",
                        trend_positive=True,
                    ),
                    KpiCard(
                        key="total_revenue",
                        label="Total App Revenue",
                        value=f"₹{total_revenue:,.0f}",
                        trend_label="All-time paid purchases",
                        trend_positive=True,
                    ),
                ]
            )
            if revenue_growth is not None:
                kpis.append(
                    KpiCard(
                        key="revenue_growth",
                        label="Revenue Growth",
                        value=f"{revenue_growth:+.1f}%",
                        trend_label="Paid buys vs last month",
                        trend_positive=revenue_growth >= 0,
                    )
                )

        if user_has_permission(user, "inventory.view"):
            metal_value, metal_rows, low_stock_count = await self._digital_metal_summary()
            metal_inventory_value = metal_value
            methodology.extend(_METAL_INVENTORY_METHODOLOGY)
            kpis.extend(
                [
                    KpiCard(
                        key="metal_inventory_value",
                        label="Metal Inventory Value",
                        value=f"₹{metal_value:,.0f}",
                        trend_label="Digital gold + silver stock",
                        trend_positive=True,
                    ),
                    KpiCard(
                        key="low_stock",
                        label="Metal Stock Alerts",
                        value=str(low_stock_count),
                        trend_label="Low or out of stock metals",
                        trend_positive=low_stock_count == 0,
                    ),
                ]
            )
            for row in metal_rows:
                kpis.append(
                    KpiCard(
                        key=f"metal_{row.metal_type.lower()}",
                        label=f"{row.metal_type} Available",
                        value=f"{row.available_grams:,.2f} g",
                        trend_label=f"₹{row.rate_per_gram:,.0f}/g → ₹{row.value_inr:,.0f}",
                        trend_positive=True,
                    )
                )

        activity_trend: list[ActivityTrendPoint] = []

        overview = AnalyticsOverviewResponse(
            kpis=kpis,
            revenue_trend=revenue_trend,
            inventory_trend=inventory_trend,
            revenue_growth_percent=revenue_growth,
            activity_trend=activity_trend,
            methodology=methodology,
            daily_revenue=daily_revenue,
            monthly_revenue=monthly_revenue,
            total_revenue=total_revenue,
            metal_inventory_value=metal_inventory_value,
        )
        _cache[cache_key] = (now, overview)
        return overview

    async def get_revenue_report(
        self,
        user: User,
        start: Optional[datetime] = None,
        end: Optional[datetime] = None,
    ) -> RevenueReportResponse:
        self._require(user, "report.view")
        if not (
            user_has_permission(user, "transaction.view")
            or user_has_permission(user, "wallet.view")
        ):
            raise ForbiddenException("You do not have permission: transaction.view")

        now_dt = datetime.now(timezone.utc)
        day_start = now_dt.replace(hour=0, minute=0, second=0, microsecond=0)
        day_end = day_start.replace(hour=23, minute=59, second=59, microsecond=999999)
        month_start = day_start.replace(day=1)

        start_dt, end_dt = self._default_period(start, end, days=30)
        period = await self.app_metrics_repo.paid_revenue_period_summary(
            start=start_dt, end=end_dt
        )
        daily = await self.app_metrics_repo.paid_revenue_period_summary(
            start=day_start, end=day_end
        )
        monthly = await self.app_metrics_repo.paid_revenue_period_summary(
            start=month_start, end=day_end
        )
        total_all_time = await self.app_metrics_repo.paid_revenue_sum()
        trend = await self.app_metrics_repo.payment_revenue_trend(days=30)
        growth = await self.app_metrics_repo.payment_revenue_growth_percent()
        return RevenueReportResponse(
            period_start=start_dt,
            period_end=end_dt,
            total_revenue=total_all_time,
            daily_revenue=daily["total_revenue"],
            monthly_revenue=monthly["total_revenue"],
            transaction_count=period["transaction_count"],
            revenue_growth_percent=growth,
            daily_trend=[
                RevenueTrendPoint(
                    label=r["label"],
                    revenue=r["revenue"],
                    transaction_count=r["transaction_count"],
                )
                for r in trend
            ],
            top_customers=[],
            methodology=_APP_REVENUE_METHODOLOGY,
        )

    async def get_inventory_report(self, user: User) -> InventoryReportResponse:
        self._require(user, "report.view")
        self._require(user, "inventory.view")
        metal_value, metal_rows, low_stock_count = await self._digital_metal_summary()
        total_grams = sum((row.available_grams for row in metal_rows), Decimal("0"))
        return InventoryReportResponse(
            total_stock=int(total_grams),
            inventory_value=metal_value,
            low_stock_count=low_stock_count,
            item_count=len(metal_rows),
            by_category=[],
            movement_trend=[],
            metal_breakdown=metal_rows,
            valuation_formula=(
                "Metal inventory value = Σ (available grams × retail rate per gram) "
                "for each metal in digital_metal_inventory"
            ),
        )

    async def get_customer_report(self, user: User) -> CustomerReportResponse:
        self._require(user, "report.view")
        self._require(user, "customer.view")
        summary = await self.report_repo.customer_summary()
        top = await self.report_repo.top_customers_report(limit=10)
        by_type = await self.report_repo.customer_type_breakdown()
        return CustomerReportResponse(
            total_customers=summary["total_customers"],
            active_customers=summary["active_customers"],
            total_revenue=summary["total_revenue"],
            total_purchases=summary["total_purchases"],
            top_customers=top,
            by_type=[CustomerTypeRow(**row) for row in by_type],
        )

    async def get_transaction_report(
        self,
        user: User,
        start: Optional[datetime] = None,
        end: Optional[datetime] = None,
    ) -> TransactionReportResponse:
        self._require(user, "report.view")
        self._require(user, "transaction.view")
        start_dt, end_dt = self._default_period(start, end, days=30)
        breakdown = await self.report_repo.transaction_breakdown(start_dt, end_dt)
        total = sum(row["count"] for row in breakdown)
        return TransactionReportResponse(
            period_start=start_dt,
            period_end=end_dt,
            total_count=total,
            breakdown=[TransactionBreakdownRow(**row) for row in breakdown],
        )

    async def get_audit_report(
        self,
        user: User,
        start: Optional[datetime] = None,
        end: Optional[datetime] = None,
    ) -> AuditReportResponse:
        self._require(user, "report.view")
        self._require(user, "audit.view")
        start_dt, end_dt = self._default_period(start, end, days=30)
        breakdown = await self.report_repo.audit_action_breakdown(start_dt, end_dt)
        total = await self.report_repo.count_audit_logs(start_dt, end_dt)
        return AuditReportResponse(
            period_start=start_dt,
            period_end=end_dt,
            total_events=total,
            breakdown=[AuditBreakdownRow(**row) for row in breakdown],
        )

    async def _build_export_rows(
        self,
        report_type: ReportType,
        user: User,
        start: Optional[datetime],
        end: Optional[datetime],
    ) -> tuple[list[str], list[list], int, bool]:
        limit = settings.REPORT_EXPORT_MAX_ROWS
        headers: list[str] = []
        rows: list[list] = []
        truncated = False

        if report_type == "revenue":
            report = await self.get_revenue_report(user, start, end)
            headers = ["Date", "Revenue (INR)", "Paid Buys"]
            rows = [
                [p.label, p.revenue, p.transaction_count] for p in report.daily_trend
            ]
            rows.insert(0, ["Daily", report.daily_revenue, "—"])
            rows.insert(1, ["Monthly", report.monthly_revenue, "—"])
            rows.insert(2, ["All-time", report.total_revenue, report.transaction_count])
            return headers, rows, len(rows), False

        if report_type == "inventory":
            report = await self.get_inventory_report(user)
            headers = ["Metal", "Available (g)", "Rate/g (INR)", "Value (INR)"]
            rows = [
                [m.metal_type, m.available_grams, m.rate_per_gram, m.value_inr]
                for m in report.metal_breakdown
            ]
            rows.insert(
                0,
                ["TOTAL", report.total_stock, "—", report.inventory_value],
            )
            return headers, rows, len(rows), False

        if report_type == "customer":
            report = await self.get_customer_report(user)
            headers = ["Customer", "Revenue", "Transactions"]
            rows = [
                [c["full_name"], c["revenue"], c["transaction_count"]]
                for c in report.top_customers
            ]
            for bt in report.by_type:
                rows.append([f"TYPE:{bt.customer_type}", bt.revenue, bt.count])
            return headers, rows, len(rows), False

        if report_type == "transaction":
            self._require(user, "transaction.view")
            start_dt, end_dt = self._default_period(start, end, days=30)
            items = await self.report_repo.list_transactions_for_report(
                start_dt, end_dt, limit=limit + 1
            )
            truncated = len(items) > limit
            items = items[:limit]
            headers = [
                "Number",
                "Type",
                "Payment",
                "Status",
                "Total",
                "Created",
            ]
            rows = [
                [
                    t.transaction_number,
                    t.transaction_type,
                    t.payment_status,
                    t.status,
                    t.total_amount,
                    t.created_at,
                ]
                for t in items
            ]
            return headers, rows, len(items), truncated

        if report_type == "audit":
            self._require(user, "audit.view")
            if not self.audit_service:
                return [], [], 0, False
            start_dt, end_dt = self._default_period(start, end, days=30)
            total = await self.report_repo.count_audit_logs(start_dt, end_dt)
            truncated = total > limit
            logs, _ = await self.audit_service.list_audit_logs(
                skip=0,
                limit=limit,
                start_date=start_dt,
                end_date=end_dt,
            )
            headers = [
                "Timestamp",
                "Action",
                "Entity",
                "Entity ID",
                "User ID",
                "IP",
            ]
            rows = [
                [
                    log.timestamp,
                    log.action,
                    log.entity_type,
                    log.entity_id,
                    log.user_id,
                    log.ip_address,
                ]
                for log in logs
            ]
            return headers, rows, len(rows), truncated

        raise ValidationException(f"Unknown report type: {report_type}")

    async def export_report(
        self,
        report_type: ReportType,
        fmt: ExportFormat,
        user: User,
        *,
        start: Optional[datetime] = None,
        end: Optional[datetime] = None,
        performing_user_id: Optional[uuid.UUID] = None,
    ) -> tuple[bytes | str, str, str, int, bool]:
        self._require(user, "report.export")

        headers, rows, row_count, truncated = await self._build_export_rows(
            report_type, user, start, end
        )
        filename = export_filename(report_type, fmt)
        title = f"AGS Gold — {report_type.title()} Report"
        subtitle = f"Rows: {row_count}" + (" (truncated)" if truncated else "")

        if fmt == "csv":
            content: bytes | str = rows_to_csv(headers, rows)
        elif fmt == "xlsx":
            content = rows_to_xlsx(report_type.title(), headers, rows)
        elif fmt == "pdf":
            content = rows_to_pdf(title, headers, rows, subtitle=subtitle)
        else:
            raise ValidationException(f"Unsupported export format: {fmt}")

        if self.audit_service:
            await self.audit_service.log_action(
                user_id=performing_user_id,
                action=audit_actions.REPORT_EXPORT,
                entity_type="Report",
                metadata={
                    "report_type": report_type,
                    "format": fmt,
                    "row_count": row_count,
                    "truncated": truncated,
                },
            )

        return content, filename, MEDIA_TYPES[fmt], row_count, truncated
