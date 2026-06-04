import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/order_repository.dart';
import '../domain/order.dart';

class OrderFilter {
  const OrderFilter({this.orderType, this.status});
  final String? orderType;
  final String? status;

  OrderFilter copyWith({
    String? orderType,
    bool clearType = false,
    String? status,
    bool clearStatus = false,
  }) {
    return OrderFilter(
      orderType: clearType ? null : (orderType ?? this.orderType),
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

final orderFilterProvider = StateProvider<OrderFilter>(
  (_) => const OrderFilter(),
);

final ordersProvider = FutureProvider<List<OrderModel>>((ref) {
  final filter = ref.watch(orderFilterProvider);
  return ref.watch(orderRepositoryProvider).getOrders(
    orderType: filter.orderType,
    status: filter.status,
  );
});

final orderDetailsProvider = FutureProvider.family<OrderModel, int>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).getOrder(orderId);
});
