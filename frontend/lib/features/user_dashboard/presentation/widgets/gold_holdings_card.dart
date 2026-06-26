import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/core/theme/aurum_consumer_theme.dart';
import 'package:ags_gold/features/user_dashboard/domain/gold_scheme.dart';
import 'package:ags_gold/features/user_dashboard/domain/kyc_status.dart';
import 'package:ags_gold/features/user_dashboard/presentation/widgets/aurum_surface_card.dart';
import 'package:ags_gold/l10n/l10n_extension.dart';

class GoldHoldingsCard extends StatelessWidget {
  final double goldGrams;
  final double goldInvestedInr;
  final KycStatus kycStatus;
  final GoldScheme? goldScheme;

  const GoldHoldingsCard({
    super.key,
    required this.goldGrams,
    required this.goldInvestedInr,
    required this.kycStatus,
    this.goldScheme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    final gramsText = '${goldGrams.toStringAsFixed(4)} g';
    final investedText = l10n.goldInvestedAmount(currency.format(goldInvestedInr));
    final scheme = goldScheme;
    String footerText;
    if (!kycStatus.isComplete) {
      footerText = l10n.completeKycToStartTrading;
    } else if (scheme != null && scheme.status.isActive) {
      footerText = l10n.goldHoldingsSchemeActiveFooter;
    } else if (scheme != null && scheme.status.isCompleted) {
      footerText = l10n.goldHoldingsFooterVerified;
    } else {
      footerText = l10n.goldHoldingsChooseSchemeFooter;
    }

    return AurumSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.monetization_on_outlined,
                  color: AppTheme.primaryGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.goldHoldings,
                style: const TextStyle(
                  color: AurumConsumerTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            gramsText,
            style: const TextStyle(
              color: AppTheme.primaryGold,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            investedText,
            style: const TextStyle(
              color: AurumConsumerTheme.textMuted,
              fontSize: 15,
            ),
          ),
          if (footerText.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AurumConsumerTheme.border),
            const SizedBox(height: 12),
            Text(
              footerText,
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
