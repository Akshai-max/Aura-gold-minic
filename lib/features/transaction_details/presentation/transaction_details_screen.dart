import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../orders/domain/order.dart';
import '../../orders/providers/order_provider.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
final _date = DateFormat('dd MMM yyyy, hh:mm a');

class TransactionDetailsScreen extends ConsumerWidget {
  const TransactionDetailsScreen({
    required this.orderId,
    super.key,
  });

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailsProvider(orderId));
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Unable to load order details: $err'),
          ),
        ),
        data: (order) {
          final isBuy = order.orderType == OrderType.buy;
          final isCompleted = order.status == OrderStatus.completed;
          final isFailed = order.status == OrderStatus.failed || order.status == OrderStatus.cancelled;

          return ResponsivePage(
            title: 'Order Status & Invoice',
            children: [
              // Status Timeline Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Progress Timeline', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      
                      // Node 1: Order Created
                      _buildTimelineNode(
                        title: 'Order Created',
                        subtitle: 'Order generated successfully',
                        timestamp: _date.format(order.createdAt),
                        isFirst: true,
                        isLast: false,
                        status: TimelineStatus.success,
                        theme: theme,
                      ),

                      // Node 2: Payment/Processing Status
                      _buildTimelineNode(
                        title: isBuy ? 'Razorpay Payment Checkout' : 'Initiate Sell Order',
                        subtitle: isCompleted 
                            ? 'Funds verified successfully' 
                            : (isFailed ? 'Transaction was rejected or failed' : 'Awaiting payment confirmation'),
                        timestamp: order.status == OrderStatus.pendingPayment ? 'PENDING' : _date.format(order.updatedAt),
                        isFirst: false,
                        isLast: false,
                        status: isCompleted 
                            ? TimelineStatus.success 
                            : (isFailed ? TimelineStatus.failed : TimelineStatus.processing),
                        theme: theme,
                      ),

                      // Node 3: Completion
                      _buildTimelineNode(
                        title: isBuy ? 'Gold Deposited to Wallet' : 'Payout Dispatched to Bank',
                        subtitle: isCompleted 
                            ? '${order.goldQuantity.toStringAsFixed(4)} g added to Available balance'
                            : (isFailed ? 'Order failed. No gold balance modified.' : 'Processing transaction...'),
                        timestamp: isCompleted ? _date.format(order.updatedAt) : '',
                        isFirst: false,
                        isLast: true,
                        status: isCompleted 
                            ? TimelineStatus.success 
                            : (isFailed ? TimelineStatus.failed : TimelineStatus.pending),
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Detail Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Receipt Summary', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(height: 24),
                      _buildReceiptRow('Transaction ID', '#${order.id}'),
                      _buildReceiptRow('Order Type', order.orderType.name.toUpperCase()),
                      _buildReceiptRow('Quantity', '${order.goldQuantity.toStringAsFixed(4)} g'),
                      _buildReceiptRow('Locked Gold Price', '${_currency.format(order.price)} / g'),
                      const Divider(height: 20),
                      _buildReceiptRow('Gold Cost Base', _currency.format(order.amount - order.fees - order.taxes)),
                      _buildReceiptRow('Processing Fees (2%)', _currency.format(order.fees)),
                      _buildReceiptRow('GST / Taxes (3%)', _currency.format(order.taxes)),
                      const Divider(height: 20),
                      _buildReceiptRow(
                        isBuy ? 'Total Paid' : 'Total Payout Received',
                        _currency.format(order.amount),
                        isBold: true,
                        textColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimelineNode({
    required String title,
    required String subtitle,
    required String timestamp,
    required bool isFirst,
    required bool isLast,
    required TimelineStatus status,
    required ThemeData theme,
  }) {
    final activeColor = status == TimelineStatus.success 
        ? Colors.green 
        : (status == TimelineStatus.failed ? theme.colorScheme.error : theme.colorScheme.primary);
    final circleColor = status == TimelineStatus.pending ? Colors.grey.shade300 : activeColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator line + circle
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2.5,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: status == TimelineStatus.success ? Colors.green : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Timeline text details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: status == TimelineStatus.pending ? Colors.grey : null,
                        ),
                      ),
                      if (timestamp.isNotEmpty)
                        Text(
                          timestamp,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

enum TimelineStatus {
  success,
  processing,
  pending,
  failed,
}
