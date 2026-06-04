import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../gold_price/data/gold_price_repository.dart';
import '../../settings/providers/trading_settings_provider.dart';
import '../../gold_wallet/data/wallet_repository.dart';
import '../../orders/domain/order.dart';
import '../data/sell_gold_repository.dart';

class SellGoldState {
  const SellGoldState({
    this.amount = 0.0,
    this.goldQuantity = 0.0,
    this.sellRate = 0.0,
    this.availableGold = 0.0,
    this.error,
    this.isLoading = false,
    this.submitting = false,
    this.createdOrder,
    this.isAmountPrimary = true,
  });

  final double amount;
  final double goldQuantity;
  final double sellRate;
  final double availableGold;
  final String? error;
  final bool isLoading;
  final bool submitting;
  final OrderModel? createdOrder;
  final bool isAmountPrimary;

  SellGoldState copyWith({
    double? amount,
    double? goldQuantity,
    double? sellRate,
    double? availableGold,
    String? error,
    bool clearError = false,
    bool? isLoading,
    bool? submitting,
    OrderModel? createdOrder,
    bool? isAmountPrimary,
  }) {
    return SellGoldState(
      amount: amount ?? this.amount,
      goldQuantity: goldQuantity ?? this.goldQuantity,
      sellRate: sellRate ?? this.sellRate,
      availableGold: availableGold ?? this.availableGold,
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
      submitting: submitting ?? this.submitting,
      createdOrder: createdOrder ?? this.createdOrder,
      isAmountPrimary: isAmountPrimary ?? this.isAmountPrimary,
    );
  }
}

class SellGoldNotifier extends StateNotifier<SellGoldState> {
  SellGoldNotifier(this._ref) : super(const SellGoldState()) {
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

    _ref.listen(walletProvider, (previous, next) {
      if (next.hasValue) {
        state = state.copyWith(availableGold: next.value!.availableGold);
        _recalculate();
      }
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

  void selectMax() {
    final available = state.availableGold;
    updateQuantity(available);
  }

  void _recalculate() {
    final priceState = _ref.read(goldPriceProvider);
    final settingsState = _ref.read(tradingSettingsProvider);
    final walletState = _ref.read(walletProvider);

    if (priceState.isLoading || settingsState.isLoading || walletState.isLoading) {
      state = state.copyWith(isLoading: true);
      return;
    }

    final marketPrice = priceState.value?.currentPrice ?? 0.0;
    final settings = settingsState.value;
    final wallet = walletState.value;

    if (marketPrice <= 0 || settings == null || wallet == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to calculate rates. Live price, wallet, or settings unavailable.',
      );
      return;
    }

    // Sell rate: sell_rate = market_price * (1 - sell_margin / 100)
    final sellRate = double.parse((marketPrice * (1 - settings.sellMargin / 100)).toStringAsFixed(2));
    final available = wallet.availableGold;

    if (state.isAmountPrimary) {
      final amount = state.amount;
      if (amount <= 0) {
        state = state.copyWith(
          isLoading: false,
          sellRate: sellRate,
          availableGold: available,
          goldQuantity: 0,
        );
        return;
      }

      final goldQuantity = double.parse((amount / sellRate).toStringAsFixed(4));

      String? error;
      if (goldQuantity > available) {
        error = 'Insufficient available gold balance (${available.toStringAsFixed(3)} g available)';
      }

      state = state.copyWith(
        isLoading: false,
        sellRate: sellRate,
        availableGold: available,
        goldQuantity: goldQuantity,
        error: error,
      );
    } else {
      final quantity = state.goldQuantity;
      if (quantity <= 0) {
        state = state.copyWith(
          isLoading: false,
          sellRate: sellRate,
          availableGold: available,
          amount: 0,
        );
        return;
      }

      final amount = double.parse((quantity * sellRate).toStringAsFixed(2));

      String? error;
      if (quantity > available) {
        error = 'Insufficient available gold balance (${available.toStringAsFixed(3)} g available)';
      }

      state = state.copyWith(
        isLoading: false,
        sellRate: sellRate,
        availableGold: available,
        amount: amount,
        error: error,
      );
    }
  }

  Future<OrderModel?> executeSell() async {
    if (state.error != null || state.goldQuantity <= 0) return null;

    state = state.copyWith(submitting: true, clearError: true);
    try {
      final repo = _ref.read(sellGoldRepositoryProvider);
      final order = await repo.createSellOrder(
        amount: state.isAmountPrimary ? state.amount : null,
        goldQuantity: state.isAmountPrimary ? null : state.goldQuantity,
      );
      state = state.copyWith(submitting: false, createdOrder: order);
      
      // Refresh wallet & portfolio
      _ref.invalidate(walletProvider);
      
      return order;
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
      return null;
    }
  }

  void reset() {
    state = const SellGoldState();
    _recalculate();
  }
}

final sellGoldNotifierProvider = StateNotifierProvider<SellGoldNotifier, SellGoldState>((ref) {
  return SellGoldNotifier(ref);
});
