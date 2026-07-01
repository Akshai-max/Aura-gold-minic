import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/core/theme/aurum_consumer_theme.dart';
import 'package:ags_gold/features/user_dashboard/domain/gold_scheme.dart';
import 'package:ags_gold/features/user_dashboard/domain/gold_scheme_utils.dart';
import 'package:ags_gold/features/user_dashboard/domain/kyc_status.dart';
import 'package:ags_gold/features/user_dashboard/presentation/providers/gold_scheme_provider.dart';
import 'package:ags_gold/features/user_dashboard/presentation/widgets/aurum_surface_card.dart';
import 'package:ags_gold/features/user_dashboard/presentation/widgets/scheme_completion_dialog.dart';
import 'package:ags_gold/core/logging/app_event_log.dart';
import 'package:ags_gold/l10n/l10n_extension.dart';

class GoldSchemeCard extends ConsumerStatefulWidget {
  final GoldScheme scheme;
  final KycStatus kycStatus;

  const GoldSchemeCard({
    super.key,
    required this.scheme,
    required this.kycStatus,
  });

  @override
  ConsumerState<GoldSchemeCard> createState() => _GoldSchemeCardState();
}

class _GoldSchemeCardState extends ConsumerState<GoldSchemeCard> {
  void _selectTier(int grams) {
    if (!widget.kycStatus.isComplete) return;
    AppEventLog.action('scheme_tier_selected', data: {'grams': grams});
    ref.read(pendingGoldSchemeGramsProvider.notifier).state = grams;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = widget.scheme;
    final kycReady = widget.kycStatus.isComplete;

    if (scheme.status.isCompleted) {
      final upgradeOptions = goldSchemeUpgradeOptions(scheme);

      return AurumSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              title: l10n.goldSchemeTitle,
              badge: l10n.goldSchemeCompletedBadge,
              badgeColor: AurumConsumerTheme.liveGreen,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.goldSchemeCompletedBody(
                scheme.targetGrams?.toStringAsFixed(0) ?? '',
              ),
              style: const TextStyle(
                color: AurumConsumerTheme.textMuted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.lock_open_rounded,
                  size: 18,
                  color: AurumConsumerTheme.liveGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.goldSchemeSellUnlocked,
                    style: const TextStyle(
                      color: AurumConsumerTheme.liveGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              upgradeOptions.isEmpty
                  ? l10n.goldSchemeCompletionBodyMaxTier
                  : l10n.goldSchemeCompletionBody,
              style: const TextStyle(
                color: AurumConsumerTheme.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: kycReady ? () => openSellGoldInquiry(context) : null,
              icon: const Icon(Icons.sell_outlined, size: 18),
              label: Text(l10n.goldSchemeCompletionSell),
            ),
            for (final grams in upgradeOptions) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: kycReady
                    ? () => handleSchemeUpgrade(
                          context: context,
                          ref: ref,
                          targetGrams: grams,
                        )
                    : null,
                child: Text(l10n.goldSchemeCompletionUpgrade(grams)),
              ),
            ],
          ],
        ),
      );
    }

    if (scheme.status.isActive) {
      final target = scheme.targetGrams ?? 0;
      final saved = scheme.savedGrams;
      final progress = (scheme.progressPercent / 100).clamp(0.0, 1.0);

      return AurumSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              title: l10n.goldSchemeTitle,
              badge: l10n.goldSchemeActiveBadge(target.toStringAsFixed(0)),
              badgeColor: AppTheme.primaryGold,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${saved.toStringAsFixed(3)} g',
                  style: const TextStyle(
                    color: AppTheme.primaryGold,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 4),
                  child: Text(
                    l10n.goldSchemeOfTarget(target.toStringAsFixed(0)),
                    style: const TextStyle(
                      color: AurumConsumerTheme.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AurumConsumerTheme.border,
                color: AppTheme.primaryGold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.goldSchemeProgressPercent(
                scheme.progressPercent.toStringAsFixed(0),
              ),
              style: const TextStyle(
                color: AurumConsumerTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            if (scheme.canSell)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AurumConsumerTheme.liveGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AurumConsumerTheme.liveGreen.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_open_rounded,
                      size: 18,
                      color: AurumConsumerTheme.liveGreen,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.goldSchemeSellUnlocked,
                        style: const TextStyle(
                          color: AurumConsumerTheme.liveGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AurumConsumerTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AurumConsumerTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: AurumConsumerTheme.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        scheme.sellLockedReason ?? l10n.sellBuyGoldFirst,
                        style: const TextStyle(
                          color: AurumConsumerTheme.textMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: kycReady ? () => context.push('/buy-gold?metal=gold') : null,
              icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
              label: Text(l10n.goldSchemeContinueBuying),
            ),
          ],
        ),
      );
    }

    final pendingGrams = ref.watch(pendingGoldSchemeGramsProvider);

    return AurumSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            title: l10n.goldSchemeTitle,
            badge: l10n.goldSchemeChooseBadge,
            badgeColor: AurumConsumerTheme.chipGold,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.goldSchemeChooseSubtitle,
            style: const TextStyle(
              color: AurumConsumerTheme.textMuted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final grams in const [1, 5, 10]) ...[
                Expanded(
                  child: _SchemeOption(
                    grams: grams,
                    selected: pendingGrams == grams,
                    enabled: kycReady,
                    onTap: () => _selectTier(grams),
                  ),
                ),
                if (grams != 10) const SizedBox(width: 10),
              ],
            ],
          ),
          if (pendingGrams != null && kycReady) ...[
            const SizedBox(height: 10),
            Text(
              l10n.goldSchemeTapBuyToConfirm(pendingGrams),
              style: const TextStyle(
                color: AppTheme.primaryGold,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (!kycReady) ...[
            const SizedBox(height: 12),
            Text(
              l10n.goldSchemeKycRequired,
              style: const TextStyle(
                color: AurumConsumerTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String badge;
  final Color badgeColor;

  const _Header({
    required this.title,
    required this.badge,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.savings_outlined,
            color: AppTheme.primaryGold,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AurumConsumerTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badge,
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SchemeOption extends StatelessWidget {
  final int grams;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _SchemeOption({
    required this.grams,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.primaryGold : AurumConsumerTheme.border,
              width: selected ? 2 : 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGold.withValues(alpha: enabled ? 0.10 : 0.04),
                AurumConsumerTheme.surface,
              ],
            ),
          ),
          child: Column(
            children: [
              Text(
                '${grams}g',
                style: TextStyle(
                  color: enabled
                      ? AppTheme.primaryGold
                      : AurumConsumerTheme.textMuted,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.goldSchemeTierLabel(grams),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AurumConsumerTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
