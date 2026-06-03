import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/permissions.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../auth/presentation/auth_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final role = auth.user?.role ?? AppRoles.user;
    final cards = switch (role) {
      AppRoles.admin => const [
        _MetricCard(label: 'Total Users', value: '128'),
        _MetricCard(label: 'Active Users', value: '117'),
        _MetricCard(label: 'Roles Count', value: '3'),
        _MetricCard(label: 'Audit Events', value: '412'),
      ],
      AppRoles.shareholder => const [
        _MetricCard(label: 'Analytics Overview', value: 'Ready'),
        _MetricCard(label: 'Reports Overview', value: '12'),
      ],
      _ => const [
        _MetricCard(label: 'Welcome', value: 'Active'),
        _MetricCard(label: 'Profile Status', value: '82%'),
        _MetricCard(label: 'Notifications', value: '0'),
        _MetricCard(label: 'Recent Activity', value: 'Today'),
      ],
    };

    return ResponsivePage(
      title: '${auth.user?.firstName ?? 'User'} Dashboard',
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: cards,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
