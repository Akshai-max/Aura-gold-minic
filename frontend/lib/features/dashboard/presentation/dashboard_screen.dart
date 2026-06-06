import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ags_gold/core/responsive/responsive_layout.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/services/service_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to end your current session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  // --- MOBILE LAYOUT (Bottom Navigation & App Bar) ---
  Widget _buildMobileLayout() {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AGS GOLD',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      body: _buildPageContent(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_toggle_off_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Operations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  // --- DESKTOP LAYOUT (Side Navigation Bar & Header) ---
  Widget _buildDesktopLayout() {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: IconThemeData(color: theme.colorScheme.primary),
            selectedLabelTextStyle: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            leading: Column(
              children: [
                const SizedBox(height: 16),
                const Icon(
                  Icons.monetization_on,
                  size: 40,
                  color: AppTheme.primaryGold,
                ),
                const SizedBox(height: 32),
              ],
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: _handleLogout,
                    tooltip: 'Log Out',
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history_toggle_off_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text('Operations'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content Area
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  _selectedIndex == 0
                      ? 'Dashboard Overview'
                      : _selectedIndex == 1
                      ? 'Audit Log & Operations'
                      : 'Settings',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                elevation: 0,
              ),
              body: _buildPageContent(_selectedIndex),
            ),
          ),
        ],
      ),
    );
  }

  // --- CONTENT SWITCHER ---
  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return _buildOverviewContent();
      case 1:
        return _buildOperationsContent();
      case 2:
      default:
        return _buildSettingsContent();
    }
  }

  Widget _buildOverviewContent() {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Card
          Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Operator',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You are logged into the AGS Gold enterprise framework. All operations are logged for audit compliance.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Stats Row (Responsive layout Grid)
          isDesktop
              ? Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Gold vault',
                        '142.84 kg',
                        Icons.store,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Active Users',
                        '24 Users',
                        Icons.people_outline,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'System Health',
                        'Optimal',
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildStatCard(
                      'Total Gold Vault',
                      '142.84 kg',
                      Icons.store,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Active Users',
                      '24 Users',
                      Icons.people_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'System Health',
                      'Optimal',
                      Icons.check_circle_outline,
                      Colors.green,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildOperationsContent() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Audit Trails',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: 5,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, idx) {
                final actions = [
                  'USER_LOGIN',
                  'VAULT_GOLD_DEPOSIT',
                  'PERMISSIONS_MODIFIED',
                  'ROLE_CREATED',
                  'AUDIT_LOG_EXPORTED',
                ];
                final details = [
                  'superadmin@agsgold.com logged in successfully',
                  '12.50 kg deposited into Vault Sector A',
                  'Added user:write permission to Administrator role',
                  'Role "auditor" initialized successfully',
                  'Exported range 2026-05-01 to 2026-06-01',
                ];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    child: Icon(
                      Icons.history,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    actions[idx],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(details[idx]),
                  trailing: Text('Just Now', style: theme.textTheme.bodySmall),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'App Settings Placeholder',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon, [
    Color? iconColor,
  ]) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
