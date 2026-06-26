import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ags_gold/core/responsive/responsive_layout.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/core/widgets/shared_drawer.dart';
import 'package:ags_gold/core/widgets/premium_timeline.dart';
import 'package:ags_gold/features/auth/domain/app_audience.dart';
import 'package:ags_gold/features/auth/presentation/providers/app_audience_provider.dart';
import 'package:ags_gold/features/profile/domain/profile.dart';
import 'package:ags_gold/features/profile/presentation/profile_dialogs.dart';
import 'package:ags_gold/features/profile/presentation/widgets/profile_settings_widgets.dart';
import 'package:ags_gold/features/settings/presentation/providers/settings_provider.dart';
import 'package:ags_gold/services/service_providers.dart';
import 'package:ags_gold/l10n/app_languages.dart';
import 'package:ags_gold/l10n/l10n_extension.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final audience = ref.watch(appAudienceProvider);

    return ResponsiveNavigationWrapper(
      title: context.l10n.myProfile,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          ref.invalidate(profileActivityProvider);
          ref.invalidate(userSettingsProvider);
        },
        child: profileAsync.when(
          data: (user) => audience == AppAudience.staffAdmin
              ? _AdminProfileBody(user: user)
              : _ConsumerProfileBody(user: user),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(64),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.l10n.failedToLoadProfile('$err'),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsumerProfileBody extends ConsumerWidget {
  final UserProfile user;

  const _ConsumerProfileBody({required this.user});

  String _memberSinceLine(BuildContext context) {
    final formatted = DateFormat('MMMM yyyy').format(user.createdAt);
    return context.l10n.memberSince(formatted);
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.comingSoon(feature))),
    );
  }

  Future<void> _showLanguageSheet(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final settings = await ref.read(userSettingsProvider.future);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.changeAppLanguage),
                subtitle: Text(l10n.selectPreferredLanguage),
              ),
              for (final option in kAppLanguageOptions)
                ListTile(
                  title: Text(option.nativeLabel),
                  trailing: settings.locale == option.code
                      ? const Icon(Icons.check, color: AppTheme.auraPurple)
                      : null,
                  onTap: () async {
                    await ref.read(updateUserSettingsProvider)(
                      settings.copyWith(locale: option.code),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSecuritySheet(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.password_outlined),
                title: Text(l10n.changePassword),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  showChangePasswordDialog(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(l10n.notificationPreferences),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/settings');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearCache(BuildContext context) {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.cacheCleared)),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).logout();
            },
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ColoredBox(
      color: AppTheme.profileBg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          ProfileHeaderCard(
            displayName: user.displayName,
            contactLine: user.email,
            memberSinceLine: _memberSinceLine(context),
            initials: user.initials,
            showVerifiedBadge: user.isActive,
            onAvatarTap: () => pickAndUploadAvatar(context, ref),
          ),
          ProfileSectionHeader(title: l10n.profileSettings),
          ProfileSettingsGroup(
            children: [
              ProfileSettingsTile(
                icon: Icons.badge_outlined,
                title: l10n.accountDetails,
                onTap: () => showEditProfileDialog(context, ref, user),
              ),
              ProfileSettingsTile(
                icon: Icons.description_outlined,
                title: l10n.statements,
                onTap: () => _showComingSoon(context, l10n.statements),
              ),
              ProfileSettingsTile(
                icon: Icons.verified_user_outlined,
                title: l10n.identityVerification,
                onTap: () => _showComingSoon(context, l10n.identityVerification),
              ),
              ProfileSettingsTile(
                icon: Icons.account_balance_outlined,
                title: l10n.linkedBankAccount,
                onTap: () => context.push('/bank-accounts'),
              ),
              ProfileSettingsTile(
                icon: Icons.person_add_alt_1_outlined,
                title: l10n.nomineeDetails,
                onTap: () => _showComingSoon(context, l10n.nomineeDetails),
              ),
            ],
          ),
          ProfileSectionHeader(title: l10n.autoSavings),
          ProfileSettingsGroup(
            children: [
              ProfileSettingsTile(
                icon: Icons.savings_outlined,
                title: l10n.modifyAutoSavings,
                onTap: () => _showComingSoon(context, l10n.autoSavings),
              ),
            ],
          ),
          ProfileSectionHeader(title: l10n.general),
          ProfileSettingsGroup(
            children: [
              ProfileSettingsTile(
                icon: Icons.language_outlined,
                title: l10n.changeAppLanguage,
                onTap: () => _showLanguageSheet(context, ref),
              ),
              ProfileSettingsTile(
                icon: Icons.card_giftcard_outlined,
                title: l10n.referAndEarn,
                onTap: () => context.push('/refer-and-earn'),
              ),
              ProfileSettingsTile(
                icon: Icons.confirmation_number_outlined,
                title: l10n.applyVoucher,
                onTap: () => _showComingSoon(context, l10n.applyVoucher),
              ),
              ProfileSettingsTile(
                icon: Icons.security_outlined,
                title: l10n.securityAndPermission,
                onTap: () => _showSecuritySheet(context, ref),
              ),
              ProfileSettingsTile(
                icon: Icons.gavel_outlined,
                title: l10n.digiGoldTermsTitle,
                onTap: () => context.push('/terms-and-conditions'),
              ),
              ProfileSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.privacyPolicy,
                onTap: () => context.push('/privacy-policy'),
              ),
              ProfileSettingsTile(
                icon: Icons.help_outline,
                title: l10n.helpAndSupport,
                onTap: () => _showComingSoon(context, l10n.helpAndSupport),
              ),
              ProfileSettingsTile(
                icon: Icons.chat_outlined,
                title: l10n.joinWhatsappChannel,
                onTap: () => _showComingSoon(context, l10n.joinWhatsappChannel),
              ),
              ProfileSettingsTile(
                icon: Icons.share_outlined,
                title: l10n.shareAuraGold,
                onTap: () => _showComingSoon(context, l10n.shareAuraGold),
              ),
              ProfileSettingsTile(
                icon: Icons.star_outline,
                title: l10n.rateAuraGold,
                onTap: () => _showComingSoon(context, l10n.rateAuraGold),
              ),
              ProfileSettingsTile(
                icon: Icons.cleaning_services_outlined,
                title: l10n.clearCache,
                onTap: () => _clearCache(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () => _confirmLogout(context, ref),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.auraPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                l10n.logout,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.followUsToStayUpdated,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.profileMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminProfileBody extends ConsumerWidget {
  final UserProfile user;

  const _AdminProfileBody({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(profileActivityProvider);
    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final permissions = user.effectivePermissions;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => pickAndUploadAvatar(context, ref),
                    child: Stack(
                      children: [
                        _AvatarWidget(user: user, theme: theme),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: theme.colorScheme.primary,
                            child: Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Chip(
                        label: Text(user.isActive ? 'ACTIVE' : 'INACTIVE'),
                        backgroundColor: user.isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                showEditProfileDialog(context, ref, user),
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit profile',
                          ),
                          IconButton(
                            onPressed: () =>
                                showChangePasswordDialog(context, ref),
                            icon: const Icon(Icons.lock_outline),
                            tooltip: 'Change password',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildAccountDetails(theme, user),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 6,
                      child: _buildPermissionsCard(theme, permissions),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildAccountDetails(theme, user),
                    const SizedBox(height: 24),
                    _buildPermissionsCard(theme, permissions),
                  ],
                ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  activityAsync.when(
                    data: (logs) => PremiumTimeline(
                      entries: logs
                          .map(
                            (log) => TimelineEntry(
                              title: log.action
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              subtitle:
                                  '${log.entityType ?? 'System'} activity',
                              timestamp: log.timestamp,
                              icon: Icons.history,
                            ),
                          )
                          .toList(),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Failed to load activity: $e'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetails(ThemeData theme, UserProfile user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.star_border),
              title: const Text('Superuser Access'),
              subtitle: Text(
                user.isSuperuser
                    ? 'Bypass credentials checking'
                    : 'Subject to standard RBAC checks',
              ),
              trailing: Switch(value: user.isSuperuser, onChanged: null),
            ),
            const SizedBox(height: 16),
            Text(
              'Assigned Roles',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (user.roles.isEmpty)
              const Text(
                'No roles assigned.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.roles
                    .map<Widget>(
                      (r) => Chip(
                        label: Text(r.name.toUpperCase()),
                        avatar: const Icon(
                          Icons.admin_panel_settings,
                          size: 16,
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsCard(ThemeData theme, Set<String> permissions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Effective Permissions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            if (permissions.isEmpty)
              const Text(
                'No permissions resolved.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: permissions.length,
                separatorBuilder: (_, _) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final perm = permissions.elementAt(index);
                  return Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        perm,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarWidget extends ConsumerWidget {
  final UserProfile user;
  final ThemeData theme;

  const _AvatarWidget({required this.user, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!user.hasAvatar) {
      return _initialsAvatar();
    }

    final avatarAsync = ref.watch(avatarBytesProvider);
    return avatarAsync.when(
      data: (bytes) {
        if (bytes != null) {
          return CircleAvatar(radius: 36, backgroundImage: MemoryImage(bytes));
        }
        return _initialsAvatar();
      },
      loading: () => CircleAvatar(
        radius: 36,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => _initialsAvatar(),
    );
  }

  Widget _initialsAvatar() {
    return CircleAvatar(
      radius: 36,
      backgroundColor: theme.colorScheme.primary,
      child: Text(
        user.initials,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}
