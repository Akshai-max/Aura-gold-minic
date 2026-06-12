from typing import List, Optional
from decimal import Decimal
import uuid
from pydantic import BaseModel
from app.schemas.audit_log import AuditLogResponse
from app.schemas.notification import NotificationResponse
from app.schemas.inventory import InventoryItemResponse

class LoginStatistics(BaseModel):
    today: int
    week: int
    month: int


class ActivityTrendPoint(BaseModel):
    label: str
    count: int


class InventoryDashboardMetrics(BaseModel):
    total_stock: int
    inventory_value: Decimal
    low_stock_count: int
    low_stock_items: List[InventoryItemResponse] = []


class TopCustomerDashboardMetric(BaseModel):
    customer_id: uuid.UUID
    full_name: str
    revenue: Decimal
    transaction_count: int


class TransactionDashboardMetrics(BaseModel):
    daily_revenue: Decimal
    monthly_revenue: Decimal
    top_customers: List[TopCustomerDashboardMetric] = []


class DashboardStatsResponse(BaseModel):
    recent_activity: List[AuditLogResponse]
    unread_notifications: int
    security_alerts: List[AuditLogResponse]
    recent_notifications: List[NotificationResponse]
    login_statistics: LoginStatistics
    activity_trend: List[ActivityTrendPoint] = []
    inventory_metrics: Optional[InventoryDashboardMetrics] = None
    transaction_metrics: Optional[TransactionDashboardMetrics] = None