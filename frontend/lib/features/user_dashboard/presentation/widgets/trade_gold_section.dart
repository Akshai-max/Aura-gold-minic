import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/core/theme/aurum_consumer_theme.dart';
import 'package:ags_gold/features/user_dashboard/domain/gold_scheme.dart';
import 'package:ags_gold/features/user_dashboard/domain/kyc_status.dart';
import 'package:ags_gold/features/user_dashboard/domain/metal_prices.dart';
import 'package:ags_gold/features/user_dashboard/presentation/providers/gold_scheme_provider.dart';
import 'package:ags_gold/features/user_dashboard/presentation/widgets/kyc_trading_prompt_dialog.dart';
import 'package:ags_gold/core/logging/app_event_log.dart';
import 'package:ags_gold/l10n/l10n_extension.dart';
import 'package:ags_gold/services/api_client.dart';

class TradeGoldSection extends ConsumerWidget {
  final KycStatus kycStatus;
  final GoldScheme goldScheme;

  const TradeGoldSection({
    super.key,
    required this.kycStatus,
    required this.goldScheme,
  });

  Future<void> _onTradeTap(
    BuildContext context,
    WidgetRef ref, {
    required bool isBuy,
  }) async {
    final l10n = context.l10n;

    if (!isBuy) {
      if (!goldScheme.canSell) {
        final message = goldScheme.savedGrams <= 0
            ? l10n.sellBuyGoldFirst
            : (goldScheme.sellLockedReason ?? l10n.goldSchemeSellLocked);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }
      if (!kycStatus.isComplete) {
        await showKycTradingPrompt(
          context,
          ref,
          isBuy: isBuy,
          metal: MetalType.gold,
        );
        return;
      }
      context.push('/sell-gold-inquiry');
      return;
    }

    if (!kycStatus.isComplete) {
      await showKycTradingPrompt(
        context,
        ref,
        isBuy: isBuy,
        metal: MetalType.gold,
      );
      return;
    }

    if (isBuy && goldScheme.status.isNotSelected) {
      final pending = ref.read(pendingGoldSchemeGramsProvider);
      if (pending == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.goldSchemeSelectBeforeBuy)),
        );
        return;
      }

      try {
        await ref.read(selectGoldSchemeProvider)(pending);
        ref.read(pendingGoldSchemeGramsProvider.notifier).state = null;
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.goldSchemeSelected(pending))),
        );
        // Dashboard refresh is awaited inside selectGoldSchemeProvider.
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
        return;
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.goldSchemeSelectFailed)),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;
    AppEventLog.action(
      isBuy ? 'buy_gold_tap' : 'sell_gold_tap',
      data: {'kyc_complete': kycStatus.isComplete},
    );
    context.push(isBuy ? '/buy-gold?metal=gold' : '/sell-gold?metal=gold');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final kycLocked = !kycStatus.isComplete;
    final sellLocked = !goldScheme.canSell;
    final sellLockLabel = kycLocked
        ? l10n.kycRequired
        : l10n.goldSchemeSellLockedShort;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tradeGold,
          style: const TextStyle(
            color: AurumConsumerTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _TradeCard(
                title: l10n.buyGold,
                subtitle: l10n.buyGoldSubtitleShort,
                icon: Icons.shopping_cart_outlined,
                iconColor: AppTheme.primaryGold,
                locked: kycLocked,
                lockLabel: l10n.kycRequired,
                onTap: () => _onTradeTap(context, ref, isBuy: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TradeCard(
                title: l10n.sellGold,
                subtitle: l10n.sellGoldInquirySubtitleShort,
                icon: Icons.sell_outlined,
                iconColor: AurumConsumerTheme.liveGreen,
                locked: kycLocked || sellLocked,
                lockLabel: sellLockLabel,
                onTap: () => _onTradeTap(context, ref, isBuy: false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TradeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool locked;
  final String lockLabel;
  final VoidCallback onTap;

  const _TradeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.locked,
    required this.lockLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AurumConsumerTheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AurumConsumerTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (locked)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: AurumConsumerTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        lockLabel,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AurumConsumerTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: AurumConsumerTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AurumConsumerTheme.textMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
