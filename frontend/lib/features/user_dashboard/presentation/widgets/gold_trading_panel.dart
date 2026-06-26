import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/features/user_dashboard/domain/kyc_status.dart';
import 'package:ags_gold/l10n/l10n_extension.dart';

class GoldTradingPanel extends StatelessWidget {
  final KycStatus kycStatus;

  const GoldTradingPanel({super.key, required this.kycStatus});

  void _handleAction(BuildContext context, String route) {
    final l10n = context.l10n;
    if (!kycStatus.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.kycRequiredForTrading),
          action: SnackBarAction(
            label: l10n.kycVerification,
            onPressed: () => context.push('/kyc'),
          ),
        ),
      );
      return;
    }
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tradingEnabled = kycStatus.isComplete;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.goldTrading,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        _TradingActionCard(
          icon: Icons.shopping_bag_outlined,
          title: l10n.buyGold,
          subtitle: l10n.buyGoldSubtitle,
          color: AppTheme.primaryGold,
          enabled: tradingEnabled,
          onTap: () => _handleAction(context, '/buy-gold'),
        ),
        const SizedBox(height: 12),
        _TradingActionCard(
          icon: Icons.payments_outlined,
          title: l10n.sellGold,
          subtitle: l10n.sellGoldSubtitle,
          color: AppTheme.deepNavy,
          enabled: tradingEnabled,
          onTap: () => _handleAction(context, '/sell-gold'),
        ),
      ],
    );
  }
}

class _TradingActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _TradingActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: enabled ? 0.35 : 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
