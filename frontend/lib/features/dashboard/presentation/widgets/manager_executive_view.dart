import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/features/dashboard/domain/executive_dashboard.dart';
import 'package:ags_gold/features/dashboard/presentation/widgets/dashboard_shared.dart';

class ManagerExecutiveView extends StatelessWidget {
  final ExecutiveDashboard data;

  const ManagerExecutiveView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final team = data.teamMetrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (team != null)
          dashboardKpiGrid(context, [
            DashboardKpiCard(
              label: 'Active Users',
              value: '${team.activeUsers}',
              trend: 'Team members online',
              icon: Icons.groups_outlined,
              color: AppTheme.sapphireBlue,
            ),
            DashboardKpiCard(
              label: 'Logins Today',
              value: '${team.loginsToday}',
              trend: 'Organization-wide',
              icon: Icons.login_outlined,
              color: AppTheme.primaryGold,
            ),
            DashboardKpiCard(
              label: 'Team Activity',
              value: '${team.teamActivityToday}',
              trend: 'Events today',
              icon: Icons.bolt_outlined,
              color: AppTheme.emerald,
            ),
          ]),
        const SizedBox(height: 24),
        DashboardSection(
          title: 'Stock alerts',
          actionLabel: 'Inventory',
          onAction: () => context.go('/inventory'),
          child: Card(
            child: data.inventoryAlerts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('All inventory levels are healthy.'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.inventoryAlerts.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = data.inventoryAlerts[index];
                      return ListTile(
                        onTap: () => context.go('/inventory'),
                        leading: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                        ),
                        title: Text(item.itemName),
                        subtitle: Text(
                          'Stock: ${item.stockQuantity} • Reorder: ${item.reorderLevel}',
                        ),
                        trailing: Text(
                          '₹${item.currentValue.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
