import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../orders/domain/order.dart';

final buyGoldRepositoryProvider = Provider<BuyGoldRepository>((ref) {
  return BuyGoldRepository(ref.watch(apiClientProvider));
});

class BuyGoldRepository {
  BuyGoldRepository(this._api);

  final ApiClient _api;

  Future<OrderModel> createBuyOrder({
    double? amount,
    double? goldQuantity,
  }) async {
    final response = await _api.post(
      '/buy',
      data: {
        'order_type': 'BUY',
        if (amount != null) 'amount': amount,
        if (goldQuantity != null) 'gold_quantity': goldQuantity,
      },
    );
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrderModel> verifyPayment({
    required int orderId,
    required String razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) async {
    final response = await _api.post(
      '/payments/verify',
      data: {
        'order_id': orderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_signature': razorpaySignature,
      },
    );
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }
}
