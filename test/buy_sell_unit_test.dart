import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aura_gold/features/buy_gold/providers/buy_gold_provider.dart';
import 'package:aura_gold/features/sell_gold/providers/sell_gold_provider.dart';
import 'package:aura_gold/features/buy_gold/data/buy_gold_repository.dart';
import 'package:aura_gold/features/sell_gold/data/sell_gold_repository.dart';
import 'package:aura_gold/features/gold_price/data/gold_price_repository.dart';
import 'package:aura_gold/features/gold_price/domain/gold_price.dart';
import 'package:aura_gold/features/settings/providers/trading_settings_provider.dart';
import 'package:aura_gold/features/settings/domain/trading_settings.dart';
import 'package:aura_gold/features/gold_wallet/data/wallet_repository.dart';
import 'package:aura_gold/features/gold_wallet/domain/gold_wallet.dart';
import 'package:aura_gold/features/orders/domain/order.dart';

class FakeBuyGoldRepository implements BuyGoldRepository {
  @override
  dynamic get _api => null;

  @override
  Future<OrderModel> createBuyOrder({double? amount, double? goldQuantity}) async {
    return OrderModel(
      id: 101,
      userId: 9,
      orderType: OrderType.buy,
      goldQuantity: goldQuantity ?? 1.5,
      price: 7435.28,
      amount: amount ?? 11152.92,
      fees: 223.06,
      taxes: 334.59,
      status: OrderStatus.pendingPayment,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<OrderModel> verifyPayment({
    required int orderId,
    required String razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) async {
    return OrderModel(
      id: 101,
      userId: 9,
      orderType: OrderType.buy,
      goldQuantity: 1.5,
      price: 7435.28,
      amount: 11152.92,
      fees: 223.06,
      taxes: 334.59,
      status: OrderStatus.completed,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class FakeSellGoldRepository implements SellGoldRepository {
  @override
  dynamic get _api => null;

  @override
  Future<OrderModel> createSellOrder({double? amount, double? goldQuantity}) async {
    return OrderModel(
      id: 102,
      userId: 9,
      orderType: OrderType.sell,
      goldQuantity: goldQuantity ?? 1.0,
      price: 7252.15,
      amount: amount ?? 7252.15,
      fees: 0,
      taxes: 0,
      status: OrderStatus.completed,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  late ProviderContainer container;

  final testGoldPrice = GoldPrice(
    currentPrice: 7325.40,
    price24k: 7325.40,
    price22k: 6714.95,
    priceChange: 84.20,
    percentageChange: 1.16,
    todaysHigh: 7364.90,
    todaysLow: 7241.20,
    openingPrice: 7241.20,
    source: 'Test Price Feed',
    lastUpdated: DateTime.now(),
    history: const [],
  );

  final testTradingSettings = const TradingSettings(
    buyMargin: 1.5,
    sellMargin: 1.0,
    dailyLimit: 100000.0,
    minimumPurchaseAmount: 100.0,
    maximumPurchaseAmount: 30000.0,
    tradingEnabled: true,
  );

  final testWallet = GoldWallet(
    walletId: 'w1',
    userId: '9',
    goldBalance: 5.0,
    availableGold: 3.5,
    lockedGold: 1.5,
    pendingGold: 0.0,
    totalInvested: 35000.0,
    currentValue: 36627.0,
    profitLoss: 1627.0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    container = ProviderContainer(
      overrides: [
        buyGoldRepositoryProvider.overrideWithValue(FakeBuyGoldRepository()),
        sellGoldRepositoryProvider.overrideWithValue(FakeSellGoldRepository()),
        goldPriceProvider.overrideWith((ref) async => testGoldPrice),
        tradingSettingsProvider.overrideWith((ref) async => testTradingSettings),
        walletProvider.overrideWith((ref) async => testWallet),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Buy Gold Notifier Calculations', () {
    test('Calculating grams from INR amount input', () async {
      // Allow async initialisation of dependencies
      await container.read(goldPriceProvider.future);
      await container.read(tradingSettingsProvider.future);

      final notifier = container.read(buyGoldNotifierProvider.notifier);
      
      // Update buy amount to ₹10,500
      notifier.updateAmount(10500.0);

      final state = container.read(buyGoldNotifierProvider);
      
      // Calculations:
      // buy rate = 7325.40 * 1.015 = 7435.281 -> ₹7435.28 / g
      // cost ratio = 1 + 0.03 + 0.02 = 1.05
      // gold cost = 10500 / 1.05 = ₹10000.00
      // fees (2%) = ₹200.00
      // taxes (3%) = ₹300.00
      // gold quantity = 10000.0 / 7435.28 = 1.34493... -> 1.3449 g
      expect(state.buyRate, equals(7435.28));
      expect(state.goldCost, equals(10000.0));
      expect(state.fees, equals(200.0));
      expect(state.taxes, equals(300.0));
      expect(state.goldQuantity, equals(1.3449));
      expect(state.error, isNull);
    });

    test('Calculating INR amount from grams input', () async {
      await container.read(goldPriceProvider.future);
      await container.read(tradingSettingsProvider.future);

      final notifier = container.read(buyGoldNotifierProvider.notifier);

      // Update gold quantity to 2.0 grams
      notifier.updateQuantity(2.0);

      final state = container.read(buyGoldNotifierProvider);

      // Calculations:
      // buy rate = ₹7435.28
      // gold cost = 2.0 * 7435.28 = ₹14870.56
      // fees (2%) = 14870.56 * 0.02 = ₹297.41
      // taxes (3%) = 14870.56 * 0.03 = ₹446.12
      // total amount = 14870.56 + 297.41 + 446.12 = ₹15614.09
      expect(state.amount, equals(15614.09));
      expect(state.fees, equals(297.41));
      expect(state.taxes, equals(446.12));
      expect(state.error, isNull);
    });

    test('Validating minimum and maximum limits', () async {
      await container.read(goldPriceProvider.future);
      await container.read(tradingSettingsProvider.future);

      final notifier = container.read(buyGoldNotifierProvider.notifier);

      // Under minimum buy limit (₹100)
      notifier.updateAmount(50.0);
      expect(container.read(buyGoldNotifierProvider).error, contains('Minimum purchase amount is ₹100'));

      // Over maximum buy limit (₹30,000)
      notifier.updateAmount(35000.0);
      expect(container.read(buyGoldNotifierProvider).error, contains('Maximum purchase amount is ₹30000'));
    });
  });

  group('Sell Gold Notifier Calculations', () {
    test('Calculating payout from grams input', () async {
      await container.read(goldPriceProvider.future);
      await container.read(tradingSettingsProvider.future);
      await container.read(walletProvider.future);

      final notifier = container.read(sellGoldNotifierProvider.notifier);

      // Sell 1.0 g
      notifier.updateQuantity(1.0);

      final state = container.read(sellGoldNotifierProvider);

      // Calculations:
      // sell rate = 7325.40 * 0.99 = ₹7252.15 / g
      // payout = 1 * 7252.15 = ₹7252.15
      expect(state.sellRate, equals(7252.15));
      expect(state.amount, equals(7252.15));
      expect(state.error, isNull);
    });

    test('Validating insufficient gold balance for sell', () async {
      await container.read(goldPriceProvider.future);
      await container.read(tradingSettingsProvider.future);
      await container.read(walletProvider.future);

      final notifier = container.read(sellGoldNotifierProvider.notifier);

      // We have 3.5 g available. Sell 5.0 g.
      notifier.updateQuantity(5.0);

      expect(container.read(sellGoldNotifierProvider).error, contains('Insufficient available gold balance'));
    });
  });
}
