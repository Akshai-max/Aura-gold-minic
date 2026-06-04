import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/responsive_page.dart';
import '../domain/order.dart';
import '../providers/order_provider.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final filter = ref.watch(orderFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trading History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ordersProvider);
        },
        child: ResponsivePage(
          title: 'Your Buy & Sell Orders',
          actions: [
            DropdownButton<String?>(
              value: filter.orderType,
              hint: const Text('All Types'),
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.filter_list),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Types')),
                DropdownMenuItem(value: 'BUY', child: Text('Buy Orders')),
                DropdownMenuItem(value: 'SELL', child: Text('Sell Orders')),
              ],
              onChanged: (val) {
                ref.read(orderFilterProvider.notifier).state = filter.copyWith(
                  orderType: val,
                  clearType: val == null,
                );
              },
            ),
          ],
          children: [
            ordersAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('Unable to load orders: $err'),
                ),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No orders found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          const Text('Your purchases and sales will show up here.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final isBuy = order.orderType == OrderType.buy;
                    final stateColor = _getStatusColor(order.status, theme);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: InkWell(
                        onTap: () {
                          context.push('/transaction-details/${order.id}');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: (isBuy ? theme.colorScheme.primary : theme.colorScheme.error).withValues(alpha: 0.1),
                                child: Icon(
                                  isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isBuy ? theme.colorScheme.primary : theme.colorScheme.error,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isBuy ? 'Buy Gold' : 'Sell Gold',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        Text(
                                          _currency.format(order.amount),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${order.goldQuantity.toStringAsFixed(4)} g at ${_currency.format(order.price)} / g',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: stateColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            order.status.name.toUpperCase(),
                                            style: TextStyle(
                                              color: stateColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _dateTime.format(order.createdAt),
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
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
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status, ThemeData theme) {
    return switch (status) {
      OrderStatus.completed => Colors.green,
      OrderStatus.pendingPayment || OrderStatus.created || OrderStatus.processing => Colors.amber,
      OrderStatus.failed || OrderStatus.cancelled => theme.colorScheme.error,
    };
  }
}
