import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_page.dart';
import '../data/wallet_repository.dart';
import '../domain/gold_wallet.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

class GoldWalletScreen extends ConsumerWidget {
  const GoldWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(walletProvider.future),
        child: ResponsivePage(
          title: 'Gold Wallet',
          children: [
            wallet.when(
              loading: () => const _WalletSkeleton(),
              error: (error, _) => _ErrorCard(
                message: 'Unable to load wallet: $error',
                onRetry: () => ref.invalidate(walletProvider),
              ),
              data: (data) => _WalletContent(wallet: data),
            ),
          ],
        ),
      ),
    );
  }
}

class GoldWalletCard extends ConsumerWidget {
  const GoldWalletCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final theme = Theme.of(context);

    return wallet.when(
      loading: () => const Card(child: SizedBox(height: 140)),
      error: (_, __) => const Card(child: SizedBox(height: 140)),
      data: (data) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gold Wallet',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '${data.goldBalance.toStringAsFixed(3)} g',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Current value: ${_currency.format(data.currentValue)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletContent extends StatelessWidget {
  const _WalletContent({required this.wallet});

  final GoldWallet wallet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = wallet.profitLoss >= 0;
    final trendColor = isPositive ? theme.colorScheme.success : theme.colorScheme.error;

    return Column(
      children: [
        if (wallet.isOffline) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_outlined, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Viewing offline cached wallet data. Check your network connection.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Gold Balance',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${wallet.goldBalance.toStringAsFixed(3)} grams',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: wallet.goldBalance == 0
                        ? 0
                        : wallet.availableGold / wallet.goldBalance,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.outlineVariant,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                _WalletGrid(wallet: wallet),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _MetricRow(
                  label: 'Total Invested',
                  value: _currency.format(wallet.totalInvested),
                ),
                const Divider(),
                _MetricRow(
                  label: 'Current Market Value',
                  value: _currency.format(wallet.currentValue),
                  valueColor: theme.colorScheme.primary,
                ),
                const Divider(),
                _MetricRow(
                  label: 'Total Profit/Loss',
                  value: '${isPositive ? '+' : ''}${_currency.format(wallet.profitLoss)}',
                  valueColor: trendColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletGrid extends StatelessWidget {
  const _WalletGrid({required this.wallet});

  final GoldWallet wallet;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 3 : 1,
      childAspectRatio: MediaQuery.sizeOf(context).width > 650 ? 2.5 : 3.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _GoldPill(label: 'Available Gold', value: wallet.availableGold, icon: Icons.lock_open_outlined),
        _GoldPill(label: 'Locked Gold', value: wallet.lockedGold, icon: Icons.lock_outline),
        _GoldPill(label: 'Pending Gold', value: wallet.pendingGold, icon: Icons.pending_outlined),
      ],
    );
  }
}

class _GoldPill extends StatelessWidget {
  const _GoldPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final double value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(icon, color: theme.colorScheme.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${value.toStringAsFixed(3)} g',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletSkeleton extends StatefulWidget {
  const _WalletSkeleton();

  @override
  State<_WalletSkeleton> createState() => _WalletSkeletonState();
}

class _WalletSkeletonState extends State<_WalletSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.85).animate(_controller),
      child: Column(
        children: const [
          Card(child: SizedBox(height: 200, width: double.infinity)),
          SizedBox(height: 16),
          Card(child: SizedBox(height: 160, width: double.infinity)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
