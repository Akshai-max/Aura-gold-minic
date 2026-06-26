import 'package:flutter/material.dart';
import 'package:ags_gold/core/theme/aurum_consumer_theme.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/core/utils/time_greeting.dart';
import 'package:ags_gold/features/user_dashboard/domain/kyc_status.dart';
import 'package:ags_gold/features/user_dashboard/presentation/widgets/aurum_surface_card.dart';
import 'package:ags_gold/l10n/l10n_extension.dart';

class UserDashboardWelcomeHeader extends StatelessWidget {
  final String displayName;
  final String roleLabel;
  final KycStatus kycStatus;

  const UserDashboardWelcomeHeader({
    super.key,
    required this.displayName,
    required this.roleLabel,
    required this.kycStatus,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final greeting = greetingWithName(l10n, displayName).toUpperCase();
    final subtitle = kycStatus.isComplete
        ? l10n.userDashboardVerifiedSubtitle
        : l10n.userDashboardKycUnlockSubtitle;

    return AurumSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryGold.withValues(alpha: 0.55),
                  ),
                ),
                child: Text(
                  roleLabel.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AurumConsumerTheme.liveGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.live.toUpperCase(),
                style: const TextStyle(
                  color: AurumConsumerTheme.liveGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            greeting,
            style: const TextStyle(
              color: AurumConsumerTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AurumConsumerTheme.textMuted,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.phone_android_outlined,
                size: 16,
                color: AurumConsumerTheme.liveGreen,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.mobileVerified,
                style: const TextStyle(
                  color: AurumConsumerTheme.liveGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
