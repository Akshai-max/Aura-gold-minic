import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../gold_price/data/gold_price_repository.dart';
import '../../settings/providers/trading_settings_provider.dart';
import '../../treasury/providers/treasury_provider.dart';
import '../../orders/domain/order.dart';
import '../data/buy_gold_repository.dart';

class BuyGoldState {
  const BuyGoldState({
    this.amount = 0.0,
    this.goldQuantity = 0.0,
    this.goldCost = 0.0,
    this.fees = 0.0,
    this.taxes = 0.0,
    this.spotRate = 0.0,
    this.buyRate = 0.0,
    this.error,
    this.isLoading = false,
    this.submitting = false,
    this.createdOrder,
    this.isAmountPrimary = true,
  });

  final double amount;
  final double goldQuantity;
  final double goldCost;
  final double fees;
  final double taxes;
  final double spotRate;
  final double buyRate;
  final String? error;
  final bool isLoading;
  final bool submitting;
  final OrderModel? createdOrder;
  final bool isAmountPrimary;

  BuyGoldState copyWith({
    double? amount,
    double? goldQuantity,
    double? goldCost,
    double? fees,
    double? taxes,
    double? spotRate,
    double? buyRate,
    String? error,
    bool clearError = false,
    bool? isLoading,
    bool? submitting,
    OrderModel? createdOrder,
    bool? isAmountPrimary,
  }) {
    return BuyGoldState(
      amount: amount ?? this.amount,
      goldQuantity: goldQuantity ?? this.goldQuantity,
      goldCost: goldCost ?? this.goldCost,
      fees: fees ?? this.fees,
      taxes: taxes ?? this.taxes,
      spotRate: spotRate ?? this.spotRate,
      buyRate: buyRate ?? this.buyRate,
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
      submitting: submitting ?? this.submitting,
      createdOrder: createdOrder ?? this.createdOrder,
      isAmountPrimary: isAmountPrimary ?? this.isAmountPrimary,
    );
  }
}

class BuyGoldNotifier extends StateNotifier<BuyGoldState> {
  BuyGoldNotifier(this._ref) : super(const BuyGoldState()) {
    _init();
  }

  final Ref _ref;

  void _init() {
    _ref.listen(goldPriceProvider, (previous, next) {
      _recalculate();
    }, fireImmediately: true);

    _ref.listen(tradingSettingsProvider, (previous, next) {
      _recalculate();
    }, fireImmediately: true);

    _ref.listen(treasuryProvider, (previous, next) {
      _recalculate();
    }, fireImmediately: true);
  }

  void updateAmount(double amount) {
    state = state.copyWith(
      amount: amount,
      isAmountPrimary: true,
      clearError: true,
    );
    _recalculate();
  }

  void updateQuantity(double quantity) {
    state = state.copyWith(
      goldQuantity: quantity,
      isAmountPrimary: false,
      clearError: true,
    );
    _recalculate();
  }

  void _recalculate() {
    final priceState = _ref.read(goldPriceProvider);
    final settingsState = _ref.read(tradingSettingsProvider);
    final treasuryState = _ref.read(treasuryProvider);

    if (priceState.isLoading || settingsState.isLoading || treasuryState.isLoading) {
      state = state.copyWith(isLoading: true);
      return;
    }

    final marketPrice = priceState.value?.currentPrice ?? 0.0;
    final settings = settingsState.value;
    final treasuryGold = treasuryState.value?.availableGold ?? 0.0;

    if (marketPrice <= 0 || settings == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to calculate rates. Live gold price or settings unavailable.',
      );
      return;
    }

    // Buy rate with margin: buy_rate = market_price * (1 + buy_margin / 100)
    final buyRate = double.parse((marketPrice * (1 + settings.buyMargin / 100)).toStringAsFixed(2));

    const gstRate = 0.03;
    const feeRate = 0.02;

    if (state.isAmountPrimary) {
      final amount = state.amount;
      if (amount <= 0) {
        state = state.copyWith(
          isLoading: false,
          spotRate: marketPrice,
          buyRate: buyRate,
          goldCost: 0,
          fees: 0,
          taxes: 0,
          goldQuantity: 0,
        );
        return;
      }

      // Calculations:
      // amount = gold_cost * (1 + gst + fee) -> gold_cost = amount / (1.05)
      final goldCost = double.parse((amount / (1 + gstRate + feeRate)).toStringAsFixed(2));
      final fees = double.parse((goldCost * feeRate).toStringAsFixed(2));
      final taxes = double.parse((goldCost * gstRate).toStringAsFixed(2));
      
      // Handle rounding adjustment
      var adjustedCost = goldCost;
      if (double.parse((goldCost + fees + taxes).toStringAsFixed(2)) != amount) {
        adjustedCost = double.parse((amount - fees - taxes).toStringAsFixed(2));
      }

      final goldQuantity = double.parse((adjustedCost / buyRate).toStringAsFixed(4));

      String? error;
      if (amount < settings.minimumPurchaseAmount) {
        error = 'Minimum purchase amount is ₹${settings.minimumPurchaseAmount}';
      } else if (amount > settings.maximumPurchaseAmount) {
        error = 'Maximum purchase amount is ₹${settings.maximumPurchaseAmount}';
      } else if (goldQuantity > treasuryGold) {
        error =
            'Only ${treasuryGold.toStringAsFixed(4)} g available in treasury';
      }

      state = state.copyWith(
        isLoading: false,
        spotRate: marketPrice,
        buyRate: buyRate,
        goldCost: adjustedCost,
        fees: fees,
        taxes: taxes,
        goldQuantity: goldQuantity,
        error: error,
      );
    } else {
      final quantity = state.goldQuantity;
      if (quantity <= 0) {
        state = state.copyWith(
          isLoading: false,
          spotRate: marketPrice,
          buyRate: buyRate,
          goldCost: 0,
          fees: 0,
          taxes: 0,
          amount: 0,
        );
        return;
      }

      final goldCost = double.parse((quantity * buyRate).toStringAsFixed(2));
      final fees = double.parse((goldCost * feeRate).toStringAsFixed(2));
      final taxes = double.parse((goldCost * gstRate).toStringAsFixed(2));
      final amount = double.parse((goldCost + fees + taxes).toStringAsFixed(2));

      String? error;
      if (amount < settings.minimumPurchaseAmount) {
        error = 'Order value ₹$amount is below minimum ₹${settings.minimumPurchaseAmount}';
      } else if (amount > settings.maximumPurchaseAmount) {
        error = 'Order value ₹$amount is above maximum ₹${settings.maximumPurchaseAmount}';
      } else if (quantity > treasuryGold) {
        error =
            'Only ${treasuryGold.toStringAsFixed(4)} g available in treasury';
      }

      state = state.copyWith(
        isLoading: false,
        spotRate: marketPrice,
        buyRate: buyRate,
        goldCost: goldCost,
        fees: fees,
        taxes: taxes,
        amount: amount,
        error: error,
      );
    }
  }

  Future<OrderModel?> initiateBuy() async {
    if (state.error != null || state.amount <= 0) return null;

    state = state.copyWith(submitting: true, clearError: true);
    try {
      final repo = _ref.read(buyGoldRepositoryProvider);
      final order = await repo.createBuyOrder(
        amount: state.isAmountPrimary ? state.amount : null,
        goldQuantity: state.isAmountPrimary ? null : state.goldQuantity,
      );
      state = state.copyWith(submitting: false, createdOrder: order);
      return order;
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
      return null;
    }
  }

  void reset() {
    state = const BuyGoldState();
    _recalculate();
  }
}

final buyGoldNotifierProvider = StateNotifierProvider<BuyGoldNotifier, BuyGoldState>((ref) {
  return BuyGoldNotifier(ref);
});
