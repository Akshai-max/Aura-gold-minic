import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../orders/domain/order.dart';
import '../providers/sell_gold_provider.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

class SellReviewScreen extends ConsumerStatefulWidget {
  const SellReviewScreen({super.key});

  @override
  ConsumerState<SellReviewScreen> createState() => _SellReviewScreenState();
}

class _SellReviewScreenState extends ConsumerState<SellReviewScreen> {
  int _secondsRemaining = 30;
  Timer? _timer;
  bool _priceExpired = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _priceExpired = true;
        });
      }
    });
  }

  void _refreshPrice() {
    ref.read(sellGoldNotifierProvider.notifier).reset();
    setState(() {
      _secondsRemaining = 30;
      _priceExpired = false;
    });
    _startTimer();
  }

  Future<void> _proceedToSell() async {
    if (_priceExpired) return;

    final order = await ref.read(sellGoldNotifierProvider.notifier).executeSell();
    if (order != null && mounted) {
      // Navigate directly to a status page or order details
      context.push('/payment-status', extra: {
        'order': order,
        'success': true,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final sellState = ref.watch(sellGoldNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Gold Sale'),
      ),
      body: ResponsivePage(
        title: 'Confirm Sale Details',
        children: [
          // Timer Widget
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: _priceExpired
                  ? theme.colorScheme.errorContainer.withValues(alpha: 0.1)
                  : theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _priceExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
                      color: _priceExpired ? theme.colorScheme.error : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _priceExpired
                          ? 'Selling rate expired! Recalculate rate.'
                          : 'Live rate locked for $_secondsRemaining seconds',
                      style: TextStyle(
                        color: _priceExpired ? theme.colorScheme.error : theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (_priceExpired)
                  TextButton.icon(
                    onPressed: _refreshPrice,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Invoice Details Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transaction breakdown', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Divider(height: 24),
                  _buildDetailRow('Grams Selling', '${sellState.goldQuantity.toStringAsFixed(4)} g'),
                  _buildDetailRow('Selling Price / Rate', '${_currency.format(sellState.sellRate)} / g'),
                  const Divider(height: 20),
                  _buildDetailRow('Total Gold Value', _currency.format(sellState.amount)),
                  _buildDetailRow('Taxes / Fees', '₹ 0.00'),
                  const Divider(height: 20),
                  _buildDetailRow(
                    'Instant Bank/Wallet Payout',
                    _currency.format(sellState.amount),
                    isBold: true,
                    textColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Error message banner if any
          if (sellState.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                sellState.error!,
                style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Action Button
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _priceExpired || sellState.submitting ? null : _proceedToSell,
            child: sellState.submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Confirm & Sell Gold',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: textColor,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
