import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../orders/domain/order.dart';

final sellGoldRepositoryProvider = Provider<SellGoldRepository>((ref) {
  return SellGoldRepository(ref.watch(apiClientProvider));
});

class SellGoldRepository {
  SellGoldRepository(this._api);

  final ApiClient _api;

  Future<OrderModel> createSellOrder({
    double? amount,
    double? goldQuantity,
  }) async {
    final response = await _api.post(
      '/sell',
      data: {
        'order_type': 'SELL',
        if (amount != null) 'amount': amount,
        if (goldQuantity != null) 'gold_quantity': goldQuantity,
      },
    );
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }
}
