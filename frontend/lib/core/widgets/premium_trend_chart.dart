import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter/material.dart';import 'package:ags_gold/core/theme/app_theme.dart';
/// Reusable line chart with optional touch scrubbing (price + date tooltip).
class PremiumTrendChart extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<double> values;
  final List<String> labels;
  final List<String>? tooltipDates;
  final Color lineColor;
  final String? badge;
  final bool compact;
  final bool interactive;
  final Widget? bottomChild;
  final String Function(double value)? formatValue;
  final ValueChanged<ChartPointSelection?>? onSelectionChanged;
  final ValueChanged<bool>? onScrubActiveChanged;

  const PremiumTrendChart({
    super.key,
    required this.title,
    required this.subtitle,
    required this.values,
    required this.labels,
    this.tooltipDates,
    this.lineColor = AppTheme.primaryGold,
    this.badge,
    this.compact = false,
    this.interactive = false,
    this.bottomChild,
    this.formatValue,
    this.onSelectionChanged,
    this.onScrubActiveChanged,
  });

  @override
  State<PremiumTrendChart> createState() => _PremiumTrendChartState();
}

class ChartPointSelection {
  final int index;
  final double value;
  final String label;

  const ChartPointSelection({
    required this.index,
    required this.value,
    required this.label,
  });
}

class _PremiumTrendChartState extends State<PremiumTrendChart> {
  int _selectedIndex = -1;

  @override
  void didUpdateWidget(covariant PremiumTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values || oldWidget.labels != widget.labels) {
      _selectedIndex = -1;
    }
  }

  void _notifySelection(int index) {
    if (!widget.interactive) return;
    if (index < 0 || index >= widget.values.length) {
      widget.onSelectionChanged?.call(null);
      return;
    }
    widget.onSelectionChanged?.call(
      ChartPointSelection(
        index: index,
        value: widget.values[index],
        label: widget.labels[index],
      ),
    );
  }

  void _selectAtX(double x, _ChartGeometry geom, int count) {
    if (!widget.interactive || count <= 0) return;
    final idx = count <= 1
        ? 0
        : () {
            final plotX =
                (x - _ChartGeometry.horizontalInset).clamp(0.0, geom.plotWidth);
            final step = geom.stepX;
            final raw = step > 0 ? (plotX / step).round() : 0;
            return raw.clamp(0, count - 1);
          }();
    if (idx != _selectedIndex) {
      setState(() => _selectedIndex = idx);
    }
    _notifySelection(idx);
  }

  String _formatValue(double value) {
    if (widget.formatValue != null) return widget.formatValue!(value);
    return value.toStringAsFixed(2);
  }

  String _formatTooltipDate(int index) {
    final dates = widget.tooltipDates;
    if (dates != null && index >= 0 && index < dates.length) {
      final raw = dates[index];
      if (raw.isNotEmpty) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) {
          return DateFormat('M/d/yyyy').format(parsed.toLocal());
        }
        return raw;
      }
    }
    if (index >= 0 && index < widget.labels.length) {
      return widget.labels[index];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = widget.values.isEmpty
        ? List<double>.filled(7, 0.0)
        : widget.values;
    final labels = widget.labels.isEmpty
        ? ['—', '—', '—', '—', '—', '—', '—']
        : widget.labels;
    final padding = widget.compact ? 12.0 : 24.0;
    final chartHeight = widget.compact ? 180.0 : 220.0;
    final headerGap = widget.compact ? 12.0 : 24.0;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.lineColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.badge!,
                      style: TextStyle(
                        color: widget.lineColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: headerGap),
            SizedBox(
              height: chartHeight,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, chartHeight);
                  final geom = _ChartGeometry.fromValues(values, size);
                  final selected = _selectedIndex >= 0 &&
                          _selectedIndex < values.length
                      ? _selectedIndex
                      : -1;
                  Offset? tooltipAnchor;
                  String? tooltipText;

                  if (selected >= 0) {
                    tooltipAnchor = geom.pointAt(selected, values[selected]);
                    final dateLabel = _formatTooltipDate(selected);
                    tooltipText = '${_formatValue(values[selected])} | $dateLabel';
                  }

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomPaint(
                        size: size,
                        painter: _TrendChartPainter(
                          values: values,
                          labels: labels,
                          lineColor: widget.lineColor,
                          selectedIndex: selected,
                          isDark: isDark,
                          geometry: geom,
                        ),
                      ),
                      if (widget.interactive)
                        Positioned.fill(
                          child: _ChartTouchLayer(
                            onScrub: (x) =>
                                _selectAtX(x, geom, values.length),
                            onScrubStart: () =>
                                widget.onScrubActiveChanged?.call(true),
                            onScrubEnd: () =>
                                widget.onScrubActiveChanged?.call(false),
                          ),
                        ),
                      if (tooltipAnchor != null && tooltipText != null)
                        _ChartTooltip(
                          anchor: tooltipAnchor,
                          text: tooltipText,
                          chartSize: size,
                          lineColor: widget.lineColor,
                          isDark: isDark,
                        ),
                    ],
                  );
                },
              ),
            ),
            if (widget.bottomChild != null) ...[
              const SizedBox(height: 8),
              widget.bottomChild!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ChartGeometry {
  static const double horizontalInset = 14;
  static const double labelAreaHeight = 22;

  final double bottom;
  final double stepX;
  final double chartMin;
  final double chartSpan;
  final double plotWidth;

  const _ChartGeometry({
    required this.bottom,
    required this.stepX,
    required this.chartMin,
    required this.chartSpan,
    required this.plotWidth,
  });

  factory _ChartGeometry.fromValues(List<double> values, Size size) {
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final spread = maxVal - minVal;
    final chartMin = spread < 0.01 ? minVal * 0.95 : minVal - spread * 0.08;
    final chartMax = spread < 0.01 ? maxVal * 1.05 : maxVal + spread * 0.08;
    final chartSpan = (chartMax - chartMin).clamp(1.0, double.infinity);
    final bottom = size.height - labelAreaHeight;
    final plotWidth = (size.width - _ChartGeometry.horizontalInset * 2)
        .clamp(1.0, size.width);
    final stepX = plotWidth / (values.length - 1).clamp(1, values.length);
    return _ChartGeometry(
      bottom: bottom,
      stepX: stepX,
      chartMin: chartMin,
      chartSpan: chartSpan,
      plotWidth: plotWidth,
    );
  }

  Offset pointAt(int index, double value) {
    final x = _ChartGeometry.horizontalInset + index * stepX;
    final y = bottom - ((value - chartMin) / chartSpan) * bottom;
    return Offset(x, y);
  }
}

class _ChartTooltip extends StatelessWidget {
  final Offset anchor;
  final String text;
  final Size chartSize;
  final Color lineColor;
  final bool isDark;

  const _ChartTooltip({
    required this.anchor,
    required this.text,
    required this.chartSize,
    required this.lineColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const bubblePadH = 12.0;
    const bubblePadV = 7.0;
    final textStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: isDark ? Colors.white : const Color(0xFF0F172A),
    );
    final tp = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: chartSize.width - 16);
    final bubbleW = tp.width + bubblePadH * 2;
    final bubbleH = tp.height + bubblePadV * 2;
    var left = anchor.dx - bubbleW / 2;
    left = left.clamp(4.0, chartSize.width - bubbleW - 4);
    var top = anchor.dy - bubbleH - 14;
    if (top < 4) top = anchor.dy + 12;

    return Positioned(
      left: left,
      top: top,
      child: Material(
        elevation: 4,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: bubblePadH,
            vertical: bubblePadV,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: lineColor.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color lineColor;
  final int selectedIndex;
  final bool isDark;
  final _ChartGeometry geometry;

  _TrendChartPainter({
    required this.values,
    required this.labels,
    required this.lineColor,
    required this.selectedIndex,
    required this.isDark,
    required this.geometry,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final bottom = geometry.bottom;

    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = bottom - (bottom * i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final fillPath = Path();
    final chartPoints = <Offset>[
      for (var i = 0; i < values.length; i++) geometry.pointAt(i, values[i]),
    ];
    _addSmoothCurve(path, chartPoints);
    if (chartPoints.isNotEmpty) {
      fillPath.moveTo(chartPoints.first.dx, bottom);
      fillPath.lineTo(chartPoints.first.dx, chartPoints.first.dy);
      _appendSmoothCurve(fillPath, chartPoints);
      fillPath.lineTo(chartPoints.last.dx, bottom);
      fillPath.lineTo(chartPoints.first.dx, bottom);
    }

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.28),
            lineColor.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, bottom)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final labelStyle = TextStyle(
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.55),
      fontSize: 10,
      height: 1.1,
    );
    const maxLabels = 5;
    final labelStep = values.length <= maxLabels
        ? 1
        : ((values.length - 1) / (maxLabels - 1)).ceil().clamp(1, values.length);
    final indices = <int>{};
    for (var i = 0; i < values.length; i += labelStep) {
      indices.add(i);
    }
    indices.add(values.length - 1);
    final sortedIndices = indices.toList()..sort();
    double? lastLabelRight;
    for (final i in sortedIndices) {
      if (i < 0 || i >= labels.length) continue;
      final x = geometry.pointAt(i, values[i]).dx;
      final axisLabel = _axisLabel(labels[i]);
      final tp = TextPainter(
        text: TextSpan(text: axisLabel, style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout();
      var left = x - tp.width / 2;
      left = left.clamp(0.0, size.width - tp.width);
      if (lastLabelRight != null && left < lastLabelRight + 2) continue;
      lastLabelRight = left + tp.width;
      tp.paint(canvas, Offset(left, bottom + 4));
    }

    if (selectedIndex >= 0 && selectedIndex < values.length) {
      final point = geometry.pointAt(selectedIndex, values[selectedIndex]);
      final crosshair = Paint()
        ..color = lineColor.withValues(alpha: 0.45)
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(point.dx, 0),
        Offset(point.dx, bottom),
        crosshair,
      );
      canvas.drawLine(
        Offset(_ChartGeometry.horizontalInset, point.dy),
        Offset(size.width - _ChartGeometry.horizontalInset, point.dy),
        crosshair,
      );
      canvas.drawCircle(
        point,
        6,
        Paint()..color = isDark ? const Color(0xFF1E293B) : Colors.white,
      );
      canvas.drawCircle(point, 6, Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
      canvas.drawCircle(point, 3, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.lineColor != lineColor;
}

void _addSmoothCurve(Path path, List<Offset> points) {
  if (points.isEmpty) return;
  if (points.length == 1) {
    path.moveTo(points[0].dx, points[0].dy);
    return;
  }
  path.moveTo(points[0].dx, points[0].dy);
  _appendSmoothCurve(path, points);
}

void _appendSmoothCurve(Path path, List<Offset> points) {
  if (points.length < 2) return;
  for (var i = 0; i < points.length - 1; i++) {
    final p0 = i > 0 ? points[i - 1] : points[i];
    final p1 = points[i];
    final p2 = points[i + 1];
    final p3 = i + 2 < points.length ? points[i + 2] : p2;
    final cp1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
    final cp2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
  }
}

String _axisLabel(String label) {
  final trimmed = label.trim();
  if (trimmed.isEmpty) return '—';
  final shortYear = RegExp(r"^([A-Za-z]{3})\s+'(\d{2})$").firstMatch(trimmed);
  if (shortYear != null) {
    return "${shortYear.group(1)} '${shortYear.group(2)}";
  }
  final dayMonth = RegExp(r'^(\d{1,2})\s+([A-Za-z]{3})$').firstMatch(trimmed);
  if (dayMonth != null) {
    return '${dayMonth.group(1)} ${dayMonth.group(2)}';
  }
  return trimmed;
}

/// Captures touch/drag on the chart before parent scroll views can steal it.
class _ChartTouchLayer extends StatelessWidget {
  final void Function(double localX) onScrub;
  final VoidCallback? onScrubStart;
  final VoidCallback? onScrubEnd;

  const _ChartTouchLayer({
    required this.onScrub,
    this.onScrubStart,
    this.onScrubEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        onScrubStart?.call();
        onScrub(event.localPosition.dx);
      },
      onPointerMove: (event) => onScrub(event.localPosition.dx),
      onPointerUp: (_) => onScrubEnd?.call(),
      onPointerCancel: (_) => onScrubEnd?.call(),
      child: const ColoredBox(color: Colors.transparent),
    );
  }
}
