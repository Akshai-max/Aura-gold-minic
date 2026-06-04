import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/order.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(apiClientProvider));
});

class OrderRepository {
  OrderRepository(this._api);

  final ApiClient _api;

  Future<List<OrderModel>> getOrders({
    int skip = 0,
    int limit = 50,
    String? orderType,
    String? status,
  }) async {
    final response = await _api.get(
      '/orders',
      query: {
        'skip': skip,
        'limit': limit,
        if (orderType != null) 'order_type': orderType,
        if (status != null) 'status': status,
      },
    );
    final list = response.data as List<dynamic>;
    return list.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<OrderModel> getOrder(int orderId) async {
    final response = await _api.get('/orders/$orderId');
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }
}
