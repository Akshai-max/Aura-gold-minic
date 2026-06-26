import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/features/user_dashboard/presentation/widgets/live_price_sheet.dart';
import 'package:ags_gold/features/user_dashboard/domain/kyc_status.dart';
import 'package:ags_gold/features/user_dashboard/domain/metal_prices.dart';
import 'package:ags_gold/features/user_dashboard/presentation/widgets/kyc_trading_prompt_dialog.dart';
import 'package:ags_gold/l10n/l10n_extension.dart';

const _aurumPurple = Color(0xFF6236FF);
const _aurumPurpleDark = Color(0xFF4A1FD6);

class MetalSavingsPanel extends ConsumerStatefulWidget {
  final double goldSavingsGrams;
  final double silverSavingsGrams;
  final KycStatus kycStatus;

  const MetalSavingsPanel({
    super.key,
    required this.goldSavingsGrams,
    required this.silverSavingsGrams,
    required this.kycStatus,
  });

  @override
  ConsumerState<MetalSavingsPanel> createState() => _MetalSavingsPanelState();
}

class _MetalSavingsPanelState extends ConsumerState<MetalSavingsPanel> {
  MetalType _viewMetal = MetalType.gold;

  void _openLiveChart(MetalType metal) {
    showLivePriceSheet(context, initialMetal: metal);
  }

  String _tradeRoute({required bool isBuy, required MetalType metal}) {
    final metalParam = metal == MetalType.silver ? 'silver' : 'gold';
    return isBuy ? '/buy-gold?metal=$metalParam' : '/sell-gold?metal=$metalParam';
  }

  Future<void> _handleTrade(BuildContext context, {required bool isBuy}) async {
    if (!isBuy) {
      context.push('/sell-gold-inquiry');
      return;
    }

    if (!widget.kycStatus.isComplete) {
      await showKycTradingPrompt(
        context,
        ref,
        isBuy: isBuy,
        metal: _viewMetal,
      );
      return;
    }
    context.push(_tradeRoute(isBuy: isBuy, metal: _viewMetal));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isGold = _viewMetal == MetalType.gold;
    final balance = isGold ? widget.goldSavingsGrams : widget.silverSavingsGrams;
    final title = isGold ? l10n.yourGoldSavings : l10n.yourSilverSavings;
    final buyLabel = isGold ? l10n.buyGold : l10n.buySilver;
    final sellLabel = isGold ? l10n.sellGold : l10n.sellSilver;
    final tradingEnabled = widget.kycStatus.isComplete;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_aurumPurple, _aurumPurpleDark, AppTheme.deepNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _aurumPurple.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppTheme.primaryGold.withValues(alpha: 0.9),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${balance.toStringAsFixed(4)} gm',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Opacity(
            opacity: tradingEnabled ? 1 : 0.55,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleTrade(context, isBuy: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: tradingEnabled ? Colors.white70 : Colors.white38,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!tradingEnabled) ...[
                          const Icon(Icons.lock_outline, size: 16),
                          const SizedBox(width: 6),
                        ],
                        Flexible(child: Text(sellLabel, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _handleTrade(context, isBuy: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _aurumPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!tradingEnabled) ...[
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: _aurumPurple.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(child: Text(buyLabel, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!tradingEnabled) ...[
            const SizedBox(height: 10),
            Text(
              l10n.kycRequiredForTrading,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MetalChartChip(
                    key: const Key('goldSavingsChip'),
                    label: l10n.gold,
                    icon: Icons.monetization_on_outlined,
                    selected: isGold,
                    onSelect: () => setState(() => _viewMetal = MetalType.gold),
                    onOpenChart: () => _openLiveChart(MetalType.gold),
                  ),
                ),
                Expanded(
                  child: _MetalChartChip(
                    key: const Key('silverSavingsChip'),
                    label: l10n.silver,
                    icon: Icons.hexagon_outlined,
                    selected: !isGold,
                    onSelect: () => setState(() => _viewMetal = MetalType.silver),
                    onOpenChart: () => _openLiveChart(MetalType.silver),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tapMetalIconForChart,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetalChartChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onOpenChart;

  const _MetalChartChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelect,
    required this.onOpenChart,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: onOpenChart,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected ? _aurumPurple : Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? _aurumPurple : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
