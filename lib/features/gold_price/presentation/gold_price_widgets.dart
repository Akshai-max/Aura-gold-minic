import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_page.dart';
import '../data/gold_price_repository.dart';
import '../domain/gold_price.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
final _time = DateFormat('dd MMM, hh:mm a');

class GoldPriceCard extends ConsumerWidget {
  const GoldPriceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceAsync = ref.watch(goldPriceProvider);
    final theme = Theme.of(context);

    return priceAsync.when(
      loading: () => const _SkeletonCard(height: 140),
      error: (_, __) => const _SkeletonCard(height: 140),
      data: (data) {
        final isPositive = data.priceChange >= 0;
        final trendColor = isPositive ? theme.colorScheme.success : theme.colorScheme.error;

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.show_chart, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Gold Price',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      Text(
                        '${isPositive ? '+' : ''}${data.percentageChange.toStringAsFixed(2)}%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: trendColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_currency.format(data.currentPrice)} / g',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Updated ${_time.format(data.lastUpdated)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        data.source,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class GoldPriceDetailsScreen extends ConsumerStatefulWidget {
  const GoldPriceDetailsScreen({super.key});

  @override
  ConsumerState<GoldPriceDetailsScreen> createState() => _GoldPriceDetailsScreenState();
}

class _GoldPriceDetailsScreenState extends ConsumerState<GoldPriceDetailsScreen> {
  String _selectedHistoryRange = 'daily';

  @override
  Widget build(BuildContext context) {
    final priceAsync = ref.watch(goldPriceProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(goldPriceProvider.future),
        child: ResponsivePage(
          title: 'Gold Markets',
          children: [
            priceAsync.when(
              loading: () => const _DetailsSkeleton(),
              error: (error, _) => _ErrorStateCard(
                message: 'Unable to fetch live prices: $error',
                onRetry: () => ref.invalidate(goldPriceProvider),
              ),
              data: (data) => Column(
                children: [
                  _PriceHero(data: data),
                  const SizedBox(height: 16),
                  _InteractiveHistoryCard(
                    data: data,
                    selectedRange: _selectedHistoryRange,
                    onRangeChanged: (val) {
                      setState(() {
                        _selectedHistoryRange = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _MarketStatsGrid(data: data),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceHero extends StatelessWidget {
  const _PriceHero({required this.data});

  final GoldPrice data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = data.priceChange >= 0;
    final trendColor = isPositive ? theme.colorScheme.success : theme.colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Live Gold Rate',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  'Updated ${_time.format(data.lastUpdated)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${_currency.format(data.currentPrice)} / g',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${data.percentageChange.toStringAsFixed(2)}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: trendColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${isPositive ? 'Gained' : 'Dropped'} ${_currency.format(data.priceChange.abs())} today',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: trendColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: _CaratMetric(
                    label: '24 Karats (Pure)',
                    value: '${_currency.format(data.price24k)} / g',
                  ),
                ),
                Expanded(
                  child: _CaratMetric(
                    label: '22 Karats (Standard)',
                    value: '${_currency.format(data.price22k)} / g',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CaratMetric extends StatelessWidget {
  const _CaratMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _InteractiveHistoryCard extends StatefulWidget {
  const _InteractiveHistoryCard({
    required this.data,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  final GoldPrice data;
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;

  @override
  State<_InteractiveHistoryCard> createState() => _InteractiveHistoryCardState();
}

class _InteractiveHistoryCardState extends State<_InteractiveHistoryCard> {
  GoldPricePoint? _hoveredPoint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = widget.data.history;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      _hoveredPoint != null
                          ? 'Rate on ${_hoveredPoint!.label}'
                          : 'Historical Price Chart',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hoveredPoint != null
                          ? '${_currency.format(_hoveredPoint!.price)} / g'
                          : 'Gold Price Trend',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                // Compact Range Selector
                Row(
                  children: ['daily', 'weekly', 'monthly'].map((range) {
                    final isSelected = widget.selectedRange == range;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        onTap: () => widget.onRangeChanged(range),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            range[0].toUpperCase() + range.substring(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (history.isNotEmpty)
              _InteractiveSparkline(
                points: history.map((e) => e.price).toList(),
                labels: history.map((e) => e.label).toList(),
                onSelected: (index) {
                  setState(() {
                    _hoveredPoint = index != null ? history[index] : null;
                  });
                },
              )
            else
              const SizedBox(
                height: 150,
                child: Center(child: Text('No historical data available')),
              ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveSparkline extends StatefulWidget {
  const _InteractiveSparkline({
    required this.points,
    required this.labels,
    required this.onSelected,
  });

  final List<double> points;
  final List<String> labels;
  final ValueChanged<int?> onSelected;

  @override
  State<_InteractiveSparkline> createState() => _InteractiveSparklineState();
}

class _InteractiveSparklineState extends State<_InteractiveSparkline> {
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
      widget.onSelected(index);
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
        final size = Size(constraints.maxWidth, 150);
        return GestureDetector(
          onHorizontalDragUpdate: (details) => _handleTouch(details.localPosition, size),
          onHorizontalDragStart: (details) => _handleTouch(details.localPosition, size),
          onTapDown: (details) => _handleTouch(details.localPosition, size),
          onHorizontalDragEnd: (_) => _clearTouch(),
          onTapUp: (_) => _clearTouch(),
          onTapCancel: () => _clearTouch(),
          child: Container(
            height: 150,
            width: double.infinity,
            color: Colors.transparent,
            child: CustomPaint(
              size: size,
              painter: _SparklinePainter(
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

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.points,
    required this.selectedIndex,
    required this.color,
    required this.gridColor,
  });

  final List<double> points;
  final int? selectedIndex;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final maxVal = points.reduce(max);
    final minVal = points.reduce(min);
    final span = maxVal == minVal ? 1.0 : (maxVal - minVal);

    // Grid lines
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
      final y = size.height - ((points[i] - minVal) / span * (size.height - 16) + 8);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paintFill = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, paintFill);

    // Stroke
    final paintStroke = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paintStroke);

    // Touch Indicator
    if (selectedIndex != null && selectedIndex! < points.length) {
      final selectedX = selectedIndex! * widthStep;
      final selectedY = size.height - ((points[selectedIndex!] - minVal) / span * (size.height - 16) + 8);

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

      canvas.drawCircle(Offset(selectedX, selectedY), 6, Paint()..color = color);
      canvas.drawCircle(Offset(selectedX, selectedY), 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.color != color;
  }
}

class _MarketStatsGrid extends StatelessWidget {
  const _MarketStatsGrid({required this.data});

  final GoldPrice data;

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
              'Market Statistics',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _StatCell(label: "Today's High", value: _currency.format(data.todaysHigh)),
                _StatCell(label: "Today's Low", value: _currency.format(data.todaysLow)),
                _StatCell(label: "Opening Price", value: _currency.format(data.openingPrice)),
                _StatCell(label: "Data Source", value: data.source),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard({required this.height});

  final double height;

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
      opacity: Tween<double>(begin: 0.4, end: 0.85).animate(_controller),
      child: Card(
        child: SizedBox(height: widget.height, width: double.infinity),
      ),
    );
  }
}

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SkeletonCard(height: 180),
        SizedBox(height: 16),
        _SkeletonCard(height: 220),
        SizedBox(height: 16),
        _SkeletonCard(height: 140),
      ],
    );
  }
}

class _ErrorStateCard extends StatelessWidget {
  const _ErrorStateCard({required this.message, required this.onRetry});

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
