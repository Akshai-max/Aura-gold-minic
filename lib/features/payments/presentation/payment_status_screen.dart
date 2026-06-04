import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../orders/domain/order.dart';
import '../../gold_wallet/data/wallet_repository.dart';
import '../providers/payment_provider.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
final _date = DateFormat('dd MMM yyyy, hh:mm a');

class PaymentStatusScreen extends ConsumerWidget {
  const PaymentStatusScreen({
    required this.order,
    required this.success,
    super.key,
  });

  final OrderModel order;
  final bool success;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Retrieve verified order detail if we have it from the state
    final paymentState = ref.watch(paymentNotifierProvider);
    final finalOrder = paymentState.completedOrder ?? order;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Success / Failure Icon
              if (success) ...[
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.green.withValues(alpha: 0.12),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 64),
                ),
                const SizedBox(height: 20),
                Text(
                  'Payment Successful',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your gold will reflect in your wallet balance instantly.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ] else ...[
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                  child: Icon(Icons.cancel, color: theme.colorScheme.error, size: 64),
                ),
                const SizedBox(height: 20),
                Text(
                  'Payment Failed',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.error),
                ),
                const SizedBox(height: 8),
                Text(
                  paymentState.errorMessage ?? 'Your transaction could not be processed. Please check card limits or try again.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
              const SizedBox(height: 32),

              // Invoice Detail Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Transaction Summary', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(height: 24),
                      _buildReceiptRow('Order ID', '#${finalOrder.id}'),
                      _buildReceiptRow('Type', finalOrder.orderType.name.toUpperCase()),
                      _buildReceiptRow('Gold Quantity', '${finalOrder.goldQuantity.toStringAsFixed(4)} g'),
                      _buildReceiptRow('Purchase Rate', '${_currency.format(finalOrder.price)} / g'),
                      const Divider(height: 20),
                      _buildReceiptRow('Gold Cost', _currency.format(finalOrder.amount - finalOrder.fees - finalOrder.taxes)),
                      _buildReceiptRow('Processing Fees (2%)', _currency.format(finalOrder.fees)),
                      _buildReceiptRow('GST / Taxes (3%)', _currency.format(finalOrder.taxes)),
                      const Divider(height: 20),
                      _buildReceiptRow(
                        'Total Paid',
                        _currency.format(finalOrder.amount),
                        isBold: true,
                        textColor: theme.colorScheme.primary,
                      ),
                      _buildReceiptRow('Date & Time', _date.format(finalOrder.createdAt)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              if (success) ...[
                FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ref.invalidate(walletProvider); // instantly refresh wallet balances
                    context.go('/wallet');
                  },
                  child: const Text('View Wallet Balance', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Back to Dashboard'),
                ),
              ] else ...[
                FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.pop(), // Pop to checkout review
                  child: const Text('Retry Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Cancel & Go Home'),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
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
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: textColor,
              fontSize: isBold ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
