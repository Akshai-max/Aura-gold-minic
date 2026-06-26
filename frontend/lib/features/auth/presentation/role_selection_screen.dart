import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ags_gold/core/responsive/responsive_layout.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/features/auth/domain/app_audience.dart';
import 'package:ags_gold/features/auth/presentation/providers/app_audience_provider.dart';
import 'package:ags_gold/l10n/l10n_extension.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 48,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    size: 72,
                    color: AppTheme.primaryGold,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.welcomeToAgsGold,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.howWouldYouLikeToSignIn,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _AudienceCard(
                    key: const Key('endUserCard'),
                    icon: Icons.person_outline,
                    title: l10n.iAmAUser,
                    subtitle: l10n.iAmAUserSubtitle,
                    onTap: () {
                      ref
                          .read(appAudienceProvider.notifier)
                          .setAudience(AppAudience.endUser);
                      context.go('/login');
                    },
                  ),
                  const SizedBox(height: 16),
                  _AudienceCard(
                    key: const Key('staffAdminCard'),
                    icon: Icons.admin_panel_settings_outlined,
                    title: l10n.iAmStaffAdmin,
                    subtitle: l10n.iAmStaffAdminSubtitle,
                    onTap: () {
                      ref
                          .read(appAudienceProvider.notifier)
                          .setAudience(AppAudience.staffAdmin);
                      context.go('/login');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AudienceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryGold, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
