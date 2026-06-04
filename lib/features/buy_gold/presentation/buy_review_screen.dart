import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../payments/presentation/payment_methods_sheet.dart';
import '../providers/buy_gold_provider.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

class BuyReviewScreen extends ConsumerStatefulWidget {
  const BuyReviewScreen({super.key});

  @override
  ConsumerState<BuyReviewScreen> createState() => _BuyReviewScreenState();
}

class _BuyReviewScreenState extends ConsumerState<BuyReviewScreen> {
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
    ref.read(buyGoldNotifierProvider.notifier).reset();
    setState(() {
      _secondsRemaining = 30;
      _priceExpired = false;
    });
    _startTimer();
  }

  Future<void> _proceedToPayment() async {
    if (_priceExpired) return;

    final order = await ref.read(buyGoldNotifierProvider.notifier).initiateBuy();
    if (order != null && mounted) {
      // Show Razorpay simulated payment sheet
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PaymentMethodsSheet(order: order),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final buyState = ref.watch(buyGoldNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Purchase'),
      ),
      body: ResponsivePage(
        title: 'Confirm Invoice Breakdown',
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
                          ? 'Rate expired! Recalculate rate.'
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
                  Text('Invoice details', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Divider(height: 24),
                  _buildDetailRow('Grams Selected', '${buyState.goldQuantity.toStringAsFixed(4)} g'),
                  _buildDetailRow('Lock Price / Rate', '${_currency.format(buyState.buyRate)} / g'),
                  const Divider(height: 20),
                  _buildDetailRow('Base Gold Cost', _currency.format(buyState.goldCost)),
                  _buildDetailRow('Processing Fees (2%)', _currency.format(buyState.fees)),
                  _buildDetailRow('GST / Taxes (3%)', _currency.format(buyState.taxes)),
                  const Divider(height: 20),
                  _buildDetailRow(
                    'Net Payable Amount',
                    _currency.format(buyState.amount),
                    isBold: true,
                    textColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Error message banner if any
          if (buyState.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                buyState.error!,
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
            onPressed: _priceExpired || buyState.submitting ? null : _proceedToPayment,
            child: buyState.submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Confirm & Pay ${_currency.format(buyState.amount)}',
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
