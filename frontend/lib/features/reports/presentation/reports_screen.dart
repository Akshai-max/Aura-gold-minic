import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ags_gold/core/auth/permission_utils.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/core/widgets/premium_skeleton.dart';
import 'package:ags_gold/core/widgets/premium_trend_chart.dart';
import 'package:ags_gold/core/widgets/shared_drawer.dart';
import 'package:ags_gold/features/reports/domain/report.dart';
import 'package:ags_gold/features/reports/presentation/providers/reports_provider.dart';
import 'package:ags_gold/services/service_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _canExport(WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    if (profile == null) return false;
    return hasPermission(profile, 'report.export');
  }

  Future<void> _export(String reportType, String format) async {
    try {
      await ref.read(exportReportProvider)(reportType, format);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported $reportType as $format')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsOverviewProvider);
    final canExport = _canExport(ref);

    return ResponsiveNavigationWrapper(
      title: 'Reports & Analytics',
      child: Column(
        children: [
          analyticsAsync.when(
            data: (analytics) => _buildKpiStrip(analytics),
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: PremiumSkeletonList(itemCount: 2),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
          Material(
            color: Theme.of(context).cardColor,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'App Revenue'),
                Tab(text: 'Metal Inventory'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RevenueTab(canExport: canExport, onExport: _export),
                _InventoryTab(canExport: canExport, onExport: _export),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiStrip(AnalyticsOverview analytics) {
    if (analytics.kpis.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: analytics.kpis.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final kpi = analytics.kpis[index];
            return _KpiCardWidget(kpi: kpi);
          },
        ),
      ),
    );
  }
}

class _KpiCardWidget extends StatelessWidget {
  final KpiCard kpi;

  const _KpiCardWidget({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              kpi.label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              kpi.value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (kpi.trendLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                kpi.trendLabel!,
                style: TextStyle(
                  fontSize: 11,
                  color: (kpi.trendPositive ?? true)
                      ? AppTheme.emerald
                      : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MethodologySection extends StatelessWidget {
  final List<MetricMethodology> items;

  const _MethodologySection({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.sapphireBlue, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'How these numbers are calculated',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...items.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.formula,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Source: ${m.dataSource}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportBar extends StatelessWidget {
  final String reportType;
  final bool canExport;
  final Future<void> Function(String, String) onExport;

  const _ExportBar({
    required this.reportType,
    required this.canExport,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    if (!canExport) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          const Text('Export:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          for (final fmt in exportFormats)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton.icon(
                onPressed: () => onExport(reportType, fmt),
                icon: Icon(_iconFor(fmt), size: 16),
                label: Text(fmt.toUpperCase()),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(String fmt) {
    switch (fmt) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'xlsx':
        return Icons.table_chart_outlined;
      default:
        return Icons.download_outlined;
    }
  }
}

class _RevenueTab extends ConsumerWidget {
  final bool canExport;
  final Future<void> Function(String, String) onExport;

  const _RevenueTab({required this.canExport, required this.onExport});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(revenueReportProvider);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return reportAsync.when(
      data: (report) => RefreshIndicator(
        onRefresh: () => ref.refresh(revenueReportProvider.future),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _ExportBar(
              reportType: 'revenue',
              canExport: canExport,
              onExport: onExport,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: 'Daily Revenue',
                      value: currency.format(report.dailyRevenue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Monthly Revenue',
                      value: currency.format(report.monthlyRevenue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryTile(
                      label: 'All-time Revenue',
                      value: currency.format(report.totalRevenue),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: PremiumTrendChart(
                title: 'App Revenue Trend',
                subtitle: 'Paid gold/silver purchases per day (last 30 days)',
                values: report.dailyTrend.map((p) => p.revenue).toList(),
                labels: report.dailyTrend
                    .map(
                      (p) => p.label.length > 10 ? p.label.substring(5) : p.label,
                    )
                    .toList(),
                lineColor: AppTheme.emerald,
                badge: report.revenueGrowthPercent != null
                    ? '${report.revenueGrowthPercent! >= 0 ? '+' : ''}${report.revenueGrowthPercent!.toStringAsFixed(1)}% MoM'
                    : null,
              ),
            ),
            _MethodologySection(items: report.methodology),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _InventoryTab extends ConsumerWidget {
  final bool canExport;
  final Future<void> Function(String, String) onExport;

  const _InventoryTab({required this.canExport, required this.onExport});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(inventoryReportProvider);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final gramsFmt = NumberFormat('#,##0.##');

    return reportAsync.when(
      data: (report) => RefreshIndicator(
        onRefresh: () => ref.refresh(inventoryReportProvider.future),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _ExportBar(
              reportType: 'inventory',
              canExport: canExport,
              onExport: onExport,
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: 'Metal Inventory Value',
                      value: currency.format(report.inventoryValue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Stock Alerts',
                      value: '${report.lowStockCount}',
                    ),
                  ),
                ],
              ),
            ),
            if (report.metalBreakdown.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  'Valuation breakdown',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ...report.metalBreakdown.map(
                (row) => ListTile(
                  title: Text(row['metal_type'] as String? ?? ''),
                  subtitle: Text(
                    '${gramsFmt.format(_dec(row['available_grams']))} g available × '
                    '${currency.format(_dec(row['rate_per_gram']))}/g',
                  ),
                  trailing: Text(
                    currency.format(_dec(row['value_inr'])),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
            if (report.valuationFormula.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Card(
                  child: ListTile(
                    leading: Icon(Icons.functions, color: AppTheme.amber),
                    title: const Text('Valuation formula'),
                    subtitle: Text(report.valuationFormula),
                  ),
                ),
              ),
            const _MethodologySection(
              items: [
                MetricMethodology(
                  key: 'metal_inventory_value',
                  title: 'Metal Inventory Value',
                  formula:
                      'Σ (available grams × current retail rate per gram) for gold and silver',
                  dataSource: 'digital_metal_inventory + live metal prices',
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

double _dec(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
