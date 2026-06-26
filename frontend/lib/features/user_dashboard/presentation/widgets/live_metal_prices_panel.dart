import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/core/widgets/premium_trend_chart.dart';
import 'package:ags_gold/features/user_dashboard/domain/metal_prices.dart';
import 'package:ags_gold/features/user_dashboard/presentation/providers/metal_prices_provider.dart';

/// AURUM brand accent used for the live metals experience.
const _aurumPurple = Color(0xFF6236FF);
const _aurumPurpleDark = Color(0xFF4A1FD6);

class LiveMetalPricesPanel extends ConsumerStatefulWidget {
  const LiveMetalPricesPanel({super.key, this.displayName});

  final String? displayName;

  @override
  ConsumerState<LiveMetalPricesPanel> createState() =>
      _LiveMetalPricesPanelState();
}

class _LiveMetalPricesPanelState extends ConsumerState<LiveMetalPricesPanel> {
  MetalType _selected = MetalType.gold;
  ChartPointSelection? _chartSelection;

  @override
  Widget build(BuildContext context) {
    final pricesAsync = ref.watch(metalPricesProvider);
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    return pricesAsync.when(
      data: (data) => _buildPanel(context, data, currency),
      loading: () => _buildShell(
        context,
        child: const SizedBox(
          height: 280,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      ),
      error: (error, _) => _buildShell(
        context,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white70),
              const SizedBox(height: 8),
              Text(
                'Live rates unavailable',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(metalPricesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(
    BuildContext context,
    MetalPrices data,
    NumberFormat currency,
  ) {
    final quote = data.quoteFor(_selected);
    final firstName = _firstName(widget.displayName);
    final lineColor = _selected == MetalType.gold
        ? AppTheme.primaryGold
        : const Color(0xFFC0C0C0);
    final displayPrice = _chartSelection?.value ?? quote.displayPrice;

    return _buildShell(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstName != null ? 'Hello, $firstName' : 'Hello',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AURUM live market rates',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _LivePriceBadge(
                price: currency.format(displayPrice),
                unit: quote.unit,
                metal: _selected,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selected == MetalType.gold ? 'GOLD' : 'SILVER',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currency.format(displayPrice)} / gm',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          quote.isUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 18,
                          color: quote.isUp ? AppTheme.emerald : AppTheme.rose,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${quote.isUp ? '+' : ''}${quote.changePercent.toStringAsFixed(2)}% today',
                          style: TextStyle(
                            color: quote.isUp ? AppTheme.emerald : AppTheme.rose,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Updated ${DateFormat('HH:mm').format(data.refreshedAt.toLocal())}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _MetalToggle(
            selected: _selected,
            onChanged: (value) => setState(() {
              _selected = value;
              _chartSelection = null;
            }),
          ),
          const SizedBox(height: 16),
          PremiumTrendChart(
            title: '30 Day Price Trend',
            subtitle: _selected == MetalType.gold
                ? 'TN retail · 24K gold per gram'
                : 'TN retail · silver per gram',
            values: quote.trend.map((p) => p.price).toList(),
            labels: quote.trend.map((p) => p.label).toList(),
            tooltipDates: quote.trend.map((p) => p.date ?? '').toList(),
            lineColor: lineColor,
            badge: 'LIVE',
            interactive: true,
            formatValue: (v) => currency.format(v),
            onSelectionChanged: (s) => setState(() => _chartSelection = s),
          ),
        ],
      ),
    );
  }

  Widget _buildShell(BuildContext context, {required Widget child}) {
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
      child: child,
    );
  }

  String? _firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return null;
    return fullName.trim().split(' ').first;
  }
}

class _LivePriceBadge extends StatelessWidget {
  final String price;
  final String unit;
  final MetalType metal;

  const _LivePriceBadge({
    required this.price,
    required this.unit,
    required this.metal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            metal == MetalType.gold
                ? Icons.monetization_on_rounded
                : Icons.hexagon_outlined,
            color: metal == MetalType.gold
                ? AppTheme.primaryGold
                : const Color(0xFFE2E8F0),
            size: 18,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetalToggle extends StatelessWidget {
  final MetalType selected;
  final ValueChanged<MetalType> onChanged;

  const _MetalToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleChip(
              key: const Key('goldToggle'),
              label: 'Gold',
              icon: Icons.monetization_on_outlined,
              selected: selected == MetalType.gold,
              onTap: () => onChanged(MetalType.gold),
            ),
          ),
          Expanded(
            child: _ToggleChip(
              key: const Key('silverToggle'),
              label: 'Silver',
              icon: Icons.hexagon_outlined,
              selected: selected == MetalType.silver,
              onTap: () => onChanged(MetalType.silver),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? _aurumPurple : Colors.white70,
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
