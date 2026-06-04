import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../buy_gold/data/buy_gold_repository.dart';
import '../../orders/domain/order.dart';

enum PaymentVerificationStatus {
  idle,
  loading,
  success,
  failure,
}

class PaymentState {
  const PaymentState({
    this.status = PaymentVerificationStatus.idle,
    this.errorMessage,
    this.completedOrder,
  });

  final PaymentVerificationStatus status;
  final String? errorMessage;
  final OrderModel? completedOrder;

  PaymentState copyWith({
    PaymentVerificationStatus? status,
    String? errorMessage,
    OrderModel? completedOrder,
  }) {
    return PaymentState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      completedOrder: completedOrder ?? this.completedOrder,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier(this._buyGoldRepository) : super(const PaymentState());

  final BuyGoldRepository _buyGoldRepository;

  Future<bool> verifySimulatedPayment({
    required int orderId,
    required bool simulateSuccess,
  }) async {
    state = state.copyWith(status: PaymentVerificationStatus.loading);
    
    if (!simulateSuccess) {
      state = state.copyWith(
        status: PaymentVerificationStatus.failure,
        errorMessage: 'Payment cancelled or declined by card issuer.',
      );
      return false;
    }

    try {
      // Simulating successful callback parameters
      final randomPaymentId = 'pay_simulated_${DateTime.now().millisecondsSinceEpoch}';
      final randomOrderId = 'order_simulated_${DateTime.now().millisecondsSinceEpoch}';
      
      final completedOrder = await _buyGoldRepository.verifyPayment(
        orderId: orderId,
        razorpayPaymentId: randomPaymentId,
        razorpayOrderId: randomOrderId,
        razorpaySignature: 'mock_signature', // triggers the signature bypass in backend
      );

      state = state.copyWith(
        status: PaymentVerificationStatus.success,
        completedOrder: completedOrder,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: PaymentVerificationStatus.failure,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = const PaymentState();
  }
}

final paymentNotifierProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(ref.watch(buyGoldRepositoryProvider));
});
