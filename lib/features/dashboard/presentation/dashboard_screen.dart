import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/permissions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../gold_price/data/gold_price_repository.dart';
import '../../gold_price/domain/gold_price.dart';
import '../../gold_wallet/data/wallet_repository.dart';
import '../../gold_wallet/domain/gold_wallet.dart';
import '../../portfolio/data/portfolio_repository.dart';
import '../../portfolio/domain/portfolio.dart';
import '../../portfolio/presentation/portfolio_screen.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final role = auth.user?.role ?? AppRoles.user;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.refresh(portfolioProvider.future),
          ref.refresh(walletProvider.future),
          ref.refresh(goldPriceProvider.future),
        ]);
      },
      child: ResponsivePage(
        title: 'Welcome, ${auth.user?.firstName ?? 'Investor'}',
        children: [
          if (role == AppRoles.admin) ...[
            const AdminDashboardGrid(),
          ] else if (role == AppRoles.shareholder) ...[
            const ShareholderDashboardGrid(),
          ] else ...[
            const UserDashboardLayout(),
          ],
        ],
      ),
    );
  }
}

/// Redesigned user dashboard layout
class UserDashboardLayout extends ConsumerWidget {
  const UserDashboardLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortfolioHeroCard(),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 700) {
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: GoldPriceWidget()),
                  SizedBox(width: 16),
                  Expanded(child: WalletSummaryCard()),
                ],
              );
            } else {
              return const Column(
                children: [
                  GoldPriceWidget(),
                  SizedBox(height: 16),
                  WalletSummaryCard(),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 24),
        const QuickActionsCard(),
      ],
    );
  }
}

/// Portfolio Hero Card: Display total portfolio value, daily gain/loss, and a subtle trend chart
class PortfolioHeroCard extends ConsumerWidget {
  const PortfolioHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider);
    final theme = Theme.of(context);

    return portfolioAsync.when(
      loading: () => const _DashboardSkeleton(height: 180),
      error: (error, stack) => _ErrorCard(
        message: 'Could not load portfolio data',
        onRetry: () => ref.invalidate(portfolioProvider),
      ),
      data: (portfolio) {
        final dailyGain = portfolio.dailyChange;
        final dailyGainPercent = portfolio.percentageReturn; // or fallback daily percentage
        final isPositive = dailyGain >= 0;
        final trendColor = isPositive ? theme.colorScheme.success : theme.colorScheme.error;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.go('/portfolio'),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                    theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Stack(
                children: [
                  // Mini Area Chart in the background
                  if (portfolio.growth.isNotEmpty)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.2,
                        child: CustomPaint(
                          painter: _BackgroundAreaPainter(
                            points: portfolio.growth.map((e) => e.value).toList(),
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Portfolio Value',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                               decoration: BoxDecoration(
                                color: trendColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isPositive ? Icons.trending_up : Icons.trending_down,
                                    color: trendColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${isPositive ? '+' : ''}${portfolio.percentageReturn.toStringAsFixed(2)}%',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: trendColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currency.format(portfolio.currentPortfolioValue),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Daily PnL: ${isPositive ? '+' : ''}${_currency.format(dailyGain)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: trendColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Gold Price Widget: Current Price, Trend Indicator, Mini Sparkline Chart
class GoldPriceWidget extends ConsumerWidget {
  const GoldPriceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceAsync = ref.watch(goldPriceProvider);
    final theme = Theme.of(context);

    return priceAsync.when(
      loading: () => const _DashboardSkeleton(height: 150),
      error: (error, stack) => _ErrorCard(
        message: 'Could not load gold price',
        onRetry: () => ref.invalidate(goldPriceProvider),
      ),
      data: (price) {
        final isPositive = price.priceChange >= 0;
        final trendColor = isPositive ? theme.colorScheme.success : theme.colorScheme.error;

        return Card(
          child: InkWell(
            onTap: () => context.go('/gold-price'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.show_chart, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Live Gold Price',
                                style: theme.textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${isPositive ? '▲' : '▼'} ${price.percentageChange.abs().toStringAsFixed(2)}%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: trendColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_currency.format(price.currentPrice)} / g',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${price.source} • 24K',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mini sparkline
                      if (price.history.isNotEmpty)
                        SizedBox(
                          width: 80,
                          height: 40,
                          child: CustomPaint(
                            painter: _BackgroundAreaPainter(
                              points: price.history.map((e) => e.price).toList(),
                              color: trendColor,
                              isFilled: false,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Wallet Summary Card: Holdings, Available Balance, Locked Balance
class WalletSummaryCard extends ConsumerWidget {
  const WalletSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final theme = Theme.of(context);

    return walletAsync.when(
      loading: () => const _DashboardSkeleton(height: 150),
      error: (error, stack) => _ErrorCard(
        message: 'Could not load wallet data',
        onRetry: () => ref.invalidate(walletProvider),
      ),
      data: (wallet) {
        return Card(
          child: InkWell(
            onTap: () => context.go('/wallet'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Gold Wallet',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${wallet.goldBalance.toStringAsFixed(3)} g',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _BalanceItem(
                        label: 'Available',
                        value: '${wallet.availableGold.toStringAsFixed(3)} g',
                      ),
                      _BalanceItem(
                        label: 'Locked',
                        value: '${wallet.lockedGold.toStringAsFixed(3)} g',
                      ),
                      _BalanceItem(
                        label: 'Pending',
                        value: '${wallet.pendingGold.toStringAsFixed(3)} g',
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.go('/buy-gold'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Buy Gold', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/sell-gold'),
                          icon: const Icon(Icons.remove, size: 16),
                          label: const Text('Sell Gold', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BalanceItem extends StatelessWidget {
  const _BalanceItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Quick Actions Card for User
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(
                  icon: Icons.history,
                  label: 'Trading History',
                  onTap: () => context.go('/orders'),
                ),
                _ActionButton(
                  icon: Icons.account_balance,
                  label: 'Wallet',
                  onTap: () => context.go('/wallet'),
                ),
                _ActionButton(
                  icon: Icons.pie_chart,
                  label: 'Portfolio',
                  onTap: () => context.go('/portfolio'),
                ),
                _ActionButton(
                  icon: Icons.show_chart,
                  label: 'Prices',
                  onTap: () => context.go('/gold-price'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Background Area Painter for sparkline graphs
class _BackgroundAreaPainter extends CustomPainter {
  _BackgroundAreaPainter({
    required this.points,
    required this.color,
    this.isFilled = true,
    this.strokeWidth = 3.0,
  });

  final List<double> points;
  final Color color;
  final bool isFilled;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final maxVal = points.reduce(max);
    final minVal = points.reduce(min);
    final range = maxVal == minVal ? 1.0 : (maxVal - minVal);

    final path = Path();
    final widthStep = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * widthStep;
      final y = size.height - ((points[i] - minVal) / range * (size.height - 8) + 4);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (isFilled) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();

      final paintFill = Paint()
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, paintFill);
    }

    final paintStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paintStroke);
  }

  @override
  bool shouldRepaint(covariant _BackgroundAreaPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

/// Shimmer skeleton loader
class _DashboardSkeleton extends StatefulWidget {
  const _DashboardSkeleton({required this.height});

  final double height;

  @override
  State<_DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<_DashboardSkeleton>
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
      opacity: Tween<double>(begin: 0.3, end: 0.8).animate(_controller),
      child: Card(
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
        ),
      ),
    );
  }
}

/// Simple Error Card with Retry Button
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Admin Dashboard grid
class AdminDashboardGrid extends StatelessWidget {
  const AdminDashboardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metricCards = [
      const _AdminMetricCard(label: 'Total Users', value: '128', icon: Icons.people_outline),
      const _AdminMetricCard(label: 'Active Sessions', value: '117', icon: Icons.bolt),
      const _AdminMetricCard(label: 'RBAC Roles', value: '3', icon: Icons.security),
      const _AdminMetricCard(label: 'Audit Events', value: '412', icon: Icons.history),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: metricCards,
        ),
        const SizedBox(height: 16),
        const GoldPriceWidget(),
      ],
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(icon, color: theme.colorScheme.primary, size: 20),
              ],
            ),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shareholder Dashboard grid
class ShareholderDashboardGrid extends ConsumerWidget {
  const ShareholderDashboardGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shareholder Overview',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _BalanceItem(
                        label: 'Analytics State',
                        value: 'Operational',
                      ),
                    ),
                    Expanded(
                      child: _BalanceItem(
                        label: 'Pending Reports',
                        value: '0',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ShareholderPortfolioOverview(),
      ],
    );
  }
}
