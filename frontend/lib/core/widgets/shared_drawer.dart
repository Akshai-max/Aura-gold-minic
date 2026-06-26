import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ags_gold/features/auth/domain/app_audience.dart';
import 'package:ags_gold/features/auth/presentation/providers/app_audience_provider.dart';
import 'package:ags_gold/services/service_providers.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/core/theme/aurum_consumer_theme.dart';
import 'package:ags_gold/core/responsive/responsive_layout.dart';
import 'package:ags_gold/core/navigation/app_nav_destinations.dart';
import 'package:ags_gold/features/notifications/presentation/notification_drawer.dart';
import 'package:ags_gold/features/user_dashboard/presentation/widgets/live_price_app_bar_chip.dart';
import 'package:ags_gold/l10n/l10n_extension.dart';

class ResponsiveNavigationWrapper extends ConsumerWidget {
  final Widget child;
  final String title;

  const ResponsiveNavigationWrapper({
    super.key,
    required this.child,
    required this.title,
  });

  void _handleLogout(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logOutConfirmTitle),
        content: Text(l10n.logOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = GoRouterState.of(context);
    final currentPath = state.matchedLocation;
    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final profile = ref.watch(profileProvider).value;
    final audience = ref.watch(appAudienceProvider);
    final l10n = context.l10n;
    final destinations = buildNavDestinations(
      profile,
      audience: audience,
      l10n: l10n,
    );
    final selectedIndex = selectedNavIndexForPath(currentPath, destinations);

    if (isDesktop) {
      return Scaffold(
        endDrawer: const NotificationDrawer(),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  navigateToIndex(context, index, destinations),
              labelType: NavigationRailLabelType.selected,
              selectedIconTheme: IconThemeData(
                color: theme.colorScheme.primary,
              ),
              selectedLabelTextStyle: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              leading: const Column(
                children: [
                  SizedBox(height: 16),
                  Icon(
                    Icons.monetization_on,
                    size: 40,
                    color: AppTheme.primaryGold,
                  ),
                  SizedBox(height: 32),
                ],
              ),
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Scaffold(
                endDrawer: const NotificationDrawer(),
                appBar: AppBar(
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  elevation: 0,
                  actions: [
                    if (audience == AppAudience.endUser)
                      const LivePriceAppBarChip(),
                    const NotificationBellButton(),
                  ],
                ),
                body: child,
              ),
            ),
          ],
        ),
      );
    }

    final isEndUserMobile = audience == AppAudience.endUser;
    final endUserDestinations = isEndUserMobile
        ? destinations
            .where(
              (d) =>
                  d.routePrefix == '/user-dashboard' ||
                  d.routePrefix == '/profile',
            )
            .toList()
        : <AppNavDestination>[];
    final endUserNavIndex = isEndUserMobile
        ? selectedNavIndexForPath(currentPath, endUserDestinations)
        : 0;

    return Theme(
      data: isEndUserMobile ? AurumConsumerTheme.theme() : theme,
      child: Scaffold(
      backgroundColor:
          isEndUserMobile ? AurumConsumerTheme.background : null,
      endDrawer: const NotificationDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: !isEndUserMobile,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: isEndUserMobile ? 0.5 : 0,
          ),
        ),
        actions: [
          if (audience == AppAudience.endUser) const LivePriceAppBarChip(),
          const NotificationBellButton(),
        ],
      ),
      drawer: isEndUserMobile
          ? null
          : Drawer(
        child: Column(
          children: [
            Consumer(
              builder: (context, ref, _) {
                final profileAsync = ref.watch(profileProvider);
                return profileAsync.when(
                  data: (profile) => UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                    ),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        profile.initials,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    accountName: Text(
                      profile.displayName,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    accountEmail: Text(
                      profile.email,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ),
                  loading: () => UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                    ),
                    accountName: const Text('Loading...'),
                    accountEmail: const Text(''),
                  ),
                  error: (_, _) => UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                    ),
                    accountName: const Text('AGS Gold'),
                    accountEmail: const Text(''),
                  ),
                );
              },
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ...destinations.asMap().entries.map(
                    (entry) => ListTile(
                      leading: Icon(entry.value.selectedIcon),
                      title: Text(entry.value.label),
                      selected: selectedIndex == entry.key,
                      onTap: () {
                        Navigator.pop(context);
                        navigateToIndex(context, entry.key, destinations);
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      'Log Out',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _handleLogout(context, ref);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: isEndUserMobile
          ? _EndUserBottomNav(
              destinations: endUserDestinations,
              currentIndex: endUserNavIndex,
            )
          : null,
      body: child,
    ),
    );
  }
}

class _EndUserBottomNav extends StatelessWidget {
  final List<AppNavDestination> destinations;
  final int currentIndex;

  const _EndUserBottomNav({
    required this.destinations,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AurumConsumerTheme.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                label: l10n.navHome,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                selected: currentIndex == 0,
                onTap: () => navigateToIndex(context, 0, destinations),
              ),
              _NavItem(
                label: l10n.navProfile,
                icon: Icons.person_outline,
                selectedIcon: Icons.person_rounded,
                selected: currentIndex == 1,
                onTap: () => navigateToIndex(context, 1, destinations),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeBlue = Color(0xFF60A5FA);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: selected
                  ? BoxDecoration(
                      color: activeBlue.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    )
                  : null,
              child: Icon(
                selected ? selectedIcon : icon,
                color: selected ? activeBlue : AurumConsumerTheme.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? activeBlue : AurumConsumerTheme.textMuted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
