import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/core/theme/aurum_consumer_theme.dart';
import 'package:ags_gold/core/widgets/shared_drawer.dart';
import 'package:ags_gold/features/user_dashboard/presentation/providers/personal_dashboard_provider.dart';
import 'package:ags_gold/features/user_dashboard/presentation/widgets/aurum_surface_card.dart';
import 'package:ags_gold/l10n/l10n_extension.dart';

class MySavingsScreen extends ConsumerWidget {
  const MySavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dashboardAsync = ref.watch(personalDashboardProvider);
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    return Theme(
      data: AurumConsumerTheme.theme(),
      child: ResponsiveNavigationWrapper(
        title: l10n.mySavings,
        child: dashboardAsync.when(
          data: (data) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SavingsCard(
                  title: l10n.gold,
                  grams: data.goldSavingsGrams,
                  value: l10n.goldInvestedAmount(currency.format(data.goldInvestedInr)),
                  icon: Icons.monetization_on_rounded,
                  color: AppTheme.primaryGold,
                ),
                const SizedBox(height: 12),
                _SavingsCard(
                  title: l10n.silver,
                  grams: data.silverSavingsGrams,
                  value: l10n.goldInvestedAmount(
                    currency.format(data.silverInvestedInr),
                  ),
                  icon: Icons.hexagon_outlined,
                  color: const Color(0xFFC0C0C0),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.failedToLoadDashboard('$e')),
          ),
        ),
      ),
    );
  }
}

class _SavingsCard extends StatelessWidget {
  final String title;
  final double grams;
  final String value;
  final IconData icon;
  final Color color;

  const _SavingsCard({
    required this.title,
    required this.grams,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AurumSurfaceCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
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
                  style: const TextStyle(
                    color: AurumConsumerTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${grams.toStringAsFixed(4)} g',
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AurumConsumerTheme.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
