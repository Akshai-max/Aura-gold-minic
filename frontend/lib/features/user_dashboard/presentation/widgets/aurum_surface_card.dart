import 'package:flutter/material.dart';
import 'package:ags_gold/core/theme/aurum_consumer_theme.dart';

class AurumSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const AurumSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: AurumConsumerTheme.cardDecoration(color: color),
      child: child,
    );
  }
}
