import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_page.dart';
import '../data/portfolio_repository.dart';
import '../domain/portfolio.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(portfolioProvider.future),
      child: ResponsivePage(
        title: 'Portfolio',
        children: [
          portfolio.when(
            loading: () => const _PortfolioSkeleton(),
            error: (error, _) => _ErrorCard(
              message: 'Failed to load portfolio: $error',
              onRetry: () => ref.invalidate(portfolioProvider),
            ),
            data: (data) => _PortfolioContent(portfolio: data),
          ),
        ],
      ),
    );
  }
}

class PortfolioSummaryCard extends ConsumerWidget {
  const PortfolioSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);
    final theme = Theme.of(context);

    return portfolio.when(
      loading: () => const Card(child: SizedBox(height: 140)),
      error: (_, __) => const Card(child: SizedBox(height: 140)),
      data: (data) {
        final isPositive = data.profitLoss >= 0;
        final trendColor = isPositive ? theme.colorScheme.success : theme.colorScheme.error;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pie_chart_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Portfolio Summary',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _currency.format(data.currentPortfolioValue),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Invested ${_currency.format(data.investedAmount)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${isPositive ? '+' : ''}${_currency.format(data.profitLoss)} (${data.percentageReturn.toStringAsFixed(2)}%)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: trendColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShareholderPortfolioOverview extends ConsumerWidget {
  const ShareholderPortfolioOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(platformPortfolioProvider);
    final theme = Theme.of(context);

    return overview.when(
      loading: () => const Card(child: SizedBox(height: 120)),
      error: (_, __) => const Card(child: SizedBox(height: 120)),
      data: (overview) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 1,
        childAspectRatio: 2.3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _ShareholderMetric(
            label: 'Total Platform Gold',
            value: '${overview.totalGoldHoldings.toStringAsFixed(3)} g',
          ),
          _ShareholderMetric(
            label: 'Total Platform Assets',
            value: _currency.format(overview.totalPlatformAssets),
          ),
          _ShareholderMetric(
            label: 'Total Portfolio Value',
            value: _currency.format(overview.totalPortfolioValue),
          ),
        ],
      ),
    );
  }
}

class _PortfolioContent extends ConsumerStatefulWidget {
  const _PortfolioContent({required this.portfolio});

  final PortfolioSummary portfolio;

  @override
  ConsumerState<_PortfolioContent> createState() => _PortfolioContentState();
}

class _PortfolioContentState extends ConsumerState<_PortfolioContent> {
  PortfolioPoint? _selectedPoint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final portfolio = widget.portfolio;

    // Determine values to show (dynamic based on touch interaction)
    final displayValue = _selectedPoint?.value ?? portfolio.currentPortfolioValue;
    final displayLabel = _selectedPoint != null ? 'Value on ${_selectedPoint!.label}' : 'Current Value';

    final profitLoss = _selectedPoint != null
        ? displayValue - portfolio.investedAmount
        : portfolio.profitLoss;
    final percentage = portfolio.investedAmount == 0
        ? 0.0
        : (profitLoss / portfolio.investedAmount) * 100;

    final isPositive = profitLoss >= 0;
    final trendColor = isPositive ? theme.colorScheme.success : theme.colorScheme.error;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currency.format(displayValue),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isPositive ? '+' : ''}${_currency.format(profitLoss)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: trendColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${isPositive ? '+' : ''}${percentage.toStringAsFixed(2)}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: trendColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _RangeSelector(),
                const SizedBox(height: 20),
                InteractivePortfolioChart(
                  points: portfolio.growth,
                  onSelected: (point) {
                    setState(() {
                      _selectedPoint = point;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _PerformanceMetricsGrid(portfolio: portfolio),
        const SizedBox(height: 16),
        _StatsCard(portfolio: portfolio),
        const SizedBox(height: 16),
        _AllocationCard(portfolio: portfolio),
      ],
    );
  }
}

class _RangeSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedPortfolioRangeProvider);
    final theme = Theme.of(context);

    // Map PortfolioRange to short label strings
    final rangeLabels = {
      PortfolioRange.oneDay: '1D',
      PortfolioRange.oneWeek: '1W',
      PortfolioRange.oneMonth: '1M',
      PortfolioRange.threeMonths: '3M',
      PortfolioRange.oneYear: '1Y',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: PortfolioRange.values.map((range) {
        final isSelected = selected == range;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                ref.read(selectedPortfolioRangeProvider.notifier).state = range;
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Text(
                  rangeLabels[range] ?? range.label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Interactive Line/Area Chart widget using Gestures
class InteractivePortfolioChart extends StatefulWidget {
  const InteractivePortfolioChart({
    required this.points,
    required this.onSelected,
    super.key,
  });

  final List<PortfolioPoint> points;
  final ValueChanged<PortfolioPoint?> onSelected;

  @override
  State<InteractivePortfolioChart> createState() => _InteractivePortfolioChartState();
}

class _InteractivePortfolioChartState extends State<InteractivePortfolioChart> {
  int? _selectedIndex;

  void _handleTouch(Offset localPosition, Size size) {
    if (widget.points.length < 2) return;
    final widthStep = size.width / (widget.points.length - 1);
    int index = (localPosition.dx / widthStep).round();
    index = index.clamp(0, widget.points.length - 1);
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      widget.onSelected(widget.points[index]);
    }
  }

  void _clearTouch() {
    setState(() {
      _selectedIndex = null;
    });
    widget.onSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, 200);
        return GestureDetector(
          onHorizontalDragUpdate: (details) => _handleTouch(details.localPosition, size),
          onHorizontalDragStart: (details) => _handleTouch(details.localPosition, size),
          onTapDown: (details) => _handleTouch(details.localPosition, size),
          onHorizontalDragEnd: (_) => _clearTouch(),
          onTapUp: (_) => _clearTouch(),
          onTapCancel: () => _clearTouch(),
          child: Container(
            height: 200,
            width: double.infinity,
            color: Colors.transparent,
            child: CustomPaint(
              size: size,
              painter: _PortfolioChartPainter(
                points: widget.points,
                selectedIndex: _selectedIndex,
                color: theme.colorScheme.primary,
                gridColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PortfolioChartPainter extends CustomPainter {
  _PortfolioChartPainter({
    required this.points,
    required this.selectedIndex,
    required this.color,
    required this.gridColor,
  });

  final List<PortfolioPoint> points;
  final int? selectedIndex;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final values = points.map((point) => point.value).toList();
    final maxVal = values.reduce(max);
    final minVal = values.reduce(min);
    final span = maxVal == minVal ? 1.0 : (maxVal - minVal);

    // Draw horizontal grid lines
    final paintGrid = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final path = Path();
    final widthStep = size.width / (points.length - 1);

    for (var i = 0; i < points.length; i++) {
      final x = i * widthStep;
      final y = size.height - ((points[i].value - minVal) / span * (size.height - 16) + 8);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw Area Chart Fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paintFill = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, paintFill);

    // Draw Line Chart Stroke
    final paintStroke = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paintStroke);

    // Draw Crosshair Indicator if selected
    if (selectedIndex != null && selectedIndex! < points.length) {
      final selectedX = selectedIndex! * widthStep;
      final selectedY = size.height - ((points[selectedIndex!].value - minVal) / span * (size.height - 16) + 8);

      // Vertical dashed line
      final paintDashed = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..strokeWidth = 1.5;

      double startY = 0;
      const dashHeight = 5.0;
      const dashGap = 5.0;
      while (startY < size.height) {
        canvas.drawLine(
          Offset(selectedX, startY),
          Offset(selectedX, startY + dashHeight),
          paintDashed,
        );
        startY += dashHeight + dashGap;
      }

      // Indicator Dot
      final paintOuterDot = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final paintInnerDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(selectedX, selectedY), 6, paintOuterDot);
      canvas.drawCircle(Offset(selectedX, selectedY), 3, paintInnerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _PortfolioChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.color != color;
  }
}

/// Redesigned Performance Metrics Grid (Invested, Current Value, Profit/Loss, Return %)
class _PerformanceMetricsGrid extends StatelessWidget {
  const _PerformanceMetricsGrid({required this.portfolio});

  final PortfolioSummary portfolio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = portfolio.profitLoss >= 0;
    final trendColor = isPositive ? theme.colorScheme.success : theme.colorScheme.error;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _MetricItemCard(
          label: 'Invested Amount',
          value: _currency.format(portfolio.investedAmount),
          icon: Icons.account_balance_outlined,
        ),
        _MetricItemCard(
          label: 'Current Value',
          value: _currency.format(portfolio.currentPortfolioValue),
          icon: Icons.currency_rupee,
          valueColor: theme.colorScheme.primary,
        ),
        _MetricItemCard(
          label: 'Total Return PnL',
          value: '${isPositive ? '+' : ''}${_currency.format(portfolio.profitLoss)}',
          icon: Icons.analytics_outlined,
          valueColor: trendColor,
        ),
        _MetricItemCard(
          label: 'Percentage Return',
          value: '${isPositive ? '+' : ''}${portfolio.percentageReturn.toStringAsFixed(2)}%',
          icon: isPositive ? Icons.arrow_upward : Icons.arrow_downward,
          valueColor: trendColor,
        ),
      ],
    );
  }
}

class _MetricItemCard extends StatelessWidget {
  const _MetricItemCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(icon, color: theme.colorScheme.primary.withValues(alpha: 0.6), size: 18),
              ],
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.portfolio});

  final PortfolioSummary portfolio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolio Statistics',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _Row(
              label: 'Total Gold Holdings',
              value: '${portfolio.totalGoldHoldings.toStringAsFixed(3)} g',
            ),
            _Row(
              label: 'Average Buy Price',
              value: '${_currency.format(portfolio.averagePurchasePrice)} / g',
            ),
            _Row(
              label: 'Current Gold Price',
              value: '${_currency.format(portfolio.currentGoldPrice)} / g',
            ),
            _Row(
              label: 'Unrealized Returns',
              value: _currency.format(portfolio.unrealizedGainLoss),
              valueColor: portfolio.unrealizedGainLoss >= 0 ? theme.colorScheme.success : theme.colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({required this.portfolio});

  final PortfolioSummary portfolio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asset Allocation',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: portfolio.currentPortfolioValue <= 0 ? 0.0 : 1.0,
                minHeight: 10,
                backgroundColor: theme.colorScheme.outlineVariant,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            _Row(
              label: 'Gold Assets (100%)',
              value: _currency.format(portfolio.currentPortfolioValue),
            ),
            _Row(
              label: 'Cash Assets (0%)',
              value: _currency.format(0),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareholderMetric extends StatelessWidget {
  const _ShareholderMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer loader for portfolio
class _PortfolioSkeleton extends StatefulWidget {
  const _PortfolioSkeleton();

  @override
  State<_PortfolioSkeleton> createState() => _PortfolioSkeletonState();
}

class _PortfolioSkeletonState extends State<_PortfolioSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 0.8).animate(_controller),
      child: Column(
        children: const [
          Card(child: SizedBox(height: 280, width: double.infinity)),
          SizedBox(height: 16),
          Card(child: SizedBox(height: 180, width: double.infinity)),
          SizedBox(height: 16),
          Card(child: SizedBox(height: 120, width: double.infinity)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
