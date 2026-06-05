import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/permissions.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../theme/app_colors.dart';
import 'royal_components.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final canManageUsers = auth.permissions.contains(Permissions.userRead);
    final canManageSettings = auth.permissions.contains(
      Permissions.settingsManage,
    );
    final canReadAudit = auth.permissions.contains(Permissions.auditRead);
    final destinations = <_ShellDestination>[
      const _ShellDestination(
        route: '/dashboard',
        icon: Icons.space_dashboard_outlined,
        label: 'Dashboard',
      ),
      const _ShellDestination(
        route: '/profile',
        icon: Icons.person_outline_rounded,
        label: 'Profile',
      ),
      const _ShellDestination(
        route: '/wallet',
        icon: Icons.account_balance_wallet_outlined,
        label: 'Wallet',
      ),
      const _ShellDestination(
        route: '/portfolio',
        icon: Icons.donut_small_outlined,
        label: 'Portfolio',
      ),
      const _ShellDestination(
        route: '/gold-price',
        icon: Icons.candlestick_chart_outlined,
        label: 'Gold Price',
      ),
      const _ShellDestination(
        route: '/transactions',
        icon: Icons.receipt_long_outlined,
        label: 'Transactions',
      ),
      if (canManageUsers)
        const _ShellDestination(
          route: '/users',
          icon: Icons.people_outline_rounded,
          label: 'Users',
        ),
      if (auth.user?.role == AppRoles.admin)
        const _ShellDestination(
          route: '/roles',
          icon: Icons.shield_outlined,
          label: 'Roles',
        ),
      if (canReadAudit)
        const _ShellDestination(
          route: '/audit',
          icon: Icons.fact_check_outlined,
          label: 'Audit',
        ),
      if (canManageSettings)
        const _ShellDestination(
          route: '/settings',
          icon: Icons.tune_rounded,
          label: 'Settings',
        ),
      const _ShellDestination(
        route: '/orders',
        icon: Icons.history_rounded,
        label: 'Trading History',
      ),
      if (auth.user?.role == AppRoles.admin)
        const _ShellDestination(
          route: '/gold-settings',
          icon: Icons.price_change_outlined,
          label: 'Gold Settings',
        ),
      if (auth.user?.role == AppRoles.admin)
        const _ShellDestination(
          route: '/admin-trading-settings',
          icon: Icons.settings_input_component_outlined,
          label: 'Trading Settings',
        ),
      if (auth.user?.role == AppRoles.admin)
        const _ShellDestination(
          route: '/treasury',
          icon: Icons.account_balance_outlined,
          label: 'Gold Treasury',
        ),
    ];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AGS'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: canManageSettings ? () => context.go('/settings') : null,
            icon: const Icon(Icons.tune_outlined),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.royalGold.withValues(alpha: 0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex(context, destinations),
        onDestinationSelected: (index) {
          Navigator.of(context).pop();
          context.go(destinations[index].route);
        },
        children: [
          const RoyalDrawerHeader(),
          const RoyalGoldDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'NAVIGATION',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.6,
                color: isDark ? AppColors.onDarkMuted : AppColors.onLightMuted,
              ),
            ),
          ),
          for (final destination in destinations)
            NavigationDrawerDestination(
              icon: Icon(destination.icon),
              label: Text(destination.label),
            ),
        ],
      ),
      body: SafeArea(child: child),
    );
  }

  int _selectedIndex(
    BuildContext context,
    List<_ShellDestination> destinations,
  ) {
    final location = GoRouterState.of(context).uri.path;
    final index = destinations.indexWhere(
      (destination) => location.startsWith(destination.route),
    );
    return index == -1 ? 0 : index;
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.route,
    required this.icon,
    required this.label,
  });

  final String route;
  final IconData icon;
  final String label;
}
