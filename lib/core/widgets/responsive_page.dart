import 'package:flutter/material.dart';

import 'royal_components.dart';

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 900 ? 1040.0 : double.infinity;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                RoyalPageHeader(
                  title: title,
                  subtitle: subtitle,
                  actions: actions,
                ),
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        );
      },
    );
  }
}
