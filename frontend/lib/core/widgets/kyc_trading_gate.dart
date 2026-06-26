import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ags_gold/core/widgets/empty_state.dart';
import 'package:ags_gold/core/widgets/shared_drawer.dart';
import 'package:ags_gold/features/user_dashboard/presentation/providers/kyc_provider.dart';
import 'package:ags_gold/l10n/l10n_extension.dart';

/// Blocks gold buy/sell screens until KYC status is `verified`.
class KycTradingGate extends ConsumerWidget {
  final Widget child;
  final String? title;

  const KycTradingGate({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final kycAsync = ref.watch(kycStatusProvider);

    return kycAsync.when(
      data: (details) {
        if (details.status.isComplete) return child;

        return ResponsiveNavigationWrapper(
          title: title ?? l10n.goldTrading,
          child: EmptyStateWidget(
            icon: Icons.verified_user_outlined,
            title: l10n.kycRequiredForTrading,
            subtitle: l10n.kycBannerStartSubtitle,
            actionLabel: l10n.kycBannerStartAction,
            onAction: () => context.go('/kyc'),
          ),
        );
      },
      loading: () => ResponsiveNavigationWrapper(
        title: title ?? l10n.goldTrading,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => ResponsiveNavigationWrapper(
        title: title ?? l10n.goldTrading,
        child: EmptyStateWidget(
          icon: Icons.error_outline,
          title: l10n.kycRequiredForTrading,
          actionLabel: l10n.backToAurum,
          onAction: () => context.go('/user-dashboard'),
        ),
      ),
    );
  }
}
