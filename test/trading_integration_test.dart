import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_gold/main.dart';
import 'package:aura_gold/features/auth/presentation/auth_controller.dart';
import 'package:aura_gold/features/buy_gold/data/buy_gold_repository.dart';
import 'package:aura_gold/features/sell_gold/data/sell_gold_repository.dart';
import 'package:aura_gold/features/gold_wallet/data/wallet_repository.dart';
import 'package:aura_gold/features/gold_wallet/domain/gold_wallet.dart';
import 'package:aura_gold/features/gold_price/data/gold_price_repository.dart';
import 'package:aura_gold/features/portfolio/data/portfolio_repository.dart';
import 'package:aura_gold/features/orders/data/order_repository.dart';
import 'package:aura_gold/features/orders/domain/order.dart';
import 'package:aura_gold/features/orders/providers/order_provider.dart';
import 'package:aura_gold/features/settings/data/trading_settings_repository.dart';
import 'package:aura_gold/features/settings/domain/trading_settings.dart';
import 'package:aura_gold/features/settings/providers/trading_settings_provider.dart';
import 'package:aura_gold/core/storage/preferences_service.dart';

import 'mocks.dart';

class MockTradingIntegrationAuthController extends AuthController {
  MockTradingIntegrationAuthController()
      : super(MockAuthRepository(), MockSecureStorageService(), MockPreferencesService()) {
    state = const AuthState();
  }

  set debugState(AuthState nextState) {
    state = nextState;
  }

  @override
  Future<void> restore() async {}
}

class FakeIntegrationBuyRepository implements BuyGoldRepository {
  @override
  dynamic get _api => null;

  @override
  Future<OrderModel> createBuyOrder({double? amount, double? goldQuantity}) async {
    return OrderModel(
      id: 501,
      userId: 9,
      orderType: OrderType.buy,
      goldQuantity: goldQuantity ?? 1.3449,
      price: 7435.28,
      amount: amount ?? 10500.0,
      fees: 200.0,
      taxes: 300.0,
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
      id: 501,
      userId: 9,
      orderType: OrderType.buy,
      goldQuantity: 1.3449,
      price: 7435.28,
      amount: 10500.0,
      fees: 200.0,
      taxes: 300.0,
      status: OrderStatus.completed,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class FakeIntegrationSellRepository implements SellGoldRepository {
  @override
  dynamic get _api => null;

  @override
  Future<OrderModel> createSellOrder({double? amount, double? goldQuantity}) async {
    return OrderModel(
      id: 502,
      userId: 9,
      orderType: OrderType.sell,
      goldQuantity: goldQuantity ?? 1.0,
      price: 7252.15,
      amount: amount ?? 7252.15,
      fees: 0.0,
      taxes: 0.0,
      status: OrderStatus.completed,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class FakeIntegrationTradingSettingsRepo implements TradingSettingsRepository {
  @override
  dynamic get _api => null;

  @override
  Future<TradingSettings> getTradingSettings() async {
    return const TradingSettings(
      buyMargin: 1.5,
      sellMargin: 1.0,
      dailyLimit: 100000.0,
      minimumPurchaseAmount: 100.0,
      maximumPurchaseAmount: 50000.0,
      tradingEnabled: true,
    );
  }

  @override
  Future<TradingSettings> updateTradingSettings(TradingSettings settings) async {
    return settings;
  }
}

void main() {
  late MockTradingIntegrationAuthController mockAuthController;

  final testWalletInitial = GoldWallet(
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

  final testWalletAfterBuy = GoldWallet(
    walletId: 'w1',
    userId: '9',
    goldBalance: 6.3449,
    availableGold: 4.8449,
    lockedGold: 1.5,
    pendingGold: 0.0,
    totalInvested: 45500.0,
    currentValue: 46478.43,
    profitLoss: 978.43,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testTradingSettings = const TradingSettings(
    buyMargin: 1.5,
    sellMargin: 1.0,
    dailyLimit: 100000.0,
    minimumPurchaseAmount: 100.0,
    maximumPurchaseAmount: 50000.0,
    tradingEnabled: true,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppBootstrapCache.preferences = await SharedPreferences.getInstance();
    mockAuthController = MockTradingIntegrationAuthController();
  });

  group('Trading Integration Workflow Tests', () {
    testWidgets('E2E Buy Gold -> Checkout Sheet -> Verify Wallet Balance updates', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeSettingsRepo = FakeIntegrationTradingSettingsRepo();
      final buyRepo = FakeIntegrationBuyRepository();
      final sellRepo = FakeIntegrationSellRepository();

      var walletState = testWalletInitial;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) => mockAuthController),
            buyGoldRepositoryProvider.overrideWithValue(buyRepo),
            sellGoldRepositoryProvider.overrideWithValue(sellRepo),
            tradingSettingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
            tradingSettingsProvider.overrideWith((ref) async => testTradingSettings),
            tradingSettingsControllerProvider.overrideWith((ref) {
              final notifier = TradingSettingsController(fakeSettingsRepo);
              notifier.state = AsyncValue.data(testTradingSettings);
              return notifier;
            }),
            walletProvider.overrideWith((ref) async => walletState),
            portfolioProvider.overrideWith((ref) => mockPortfolioSummary),
            goldPriceProvider.overrideWith((ref) => mockGoldPrice),
            ordersProvider.overrideWith((ref) async => []),
          ],
          child: const AuraGoldApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Login screen
      expect(find.text('Secure platform access'), findsOneWidget);
      await tester.enterText(find.bySemanticsLabel('Email address'), 'user@ags.com');
      await tester.enterText(find.bySemanticsLabel('Password'), 'User@123');
      await tester.tap(find.text('SIGN IN'));

      mockAuthController.debugState = AuthState(
        user: mockUser,
        permissions: const ['dashboard.read', 'profile.manage'],
      );
      await tester.pumpAndSettle();

      // Dashboard screen
      expect(find.text('Welcome, Regular'), findsOneWidget);
      expect(find.text('Buy Gold'), findsOneWidget);

      // Tap Buy Gold
      await tester.tap(find.text('Buy Gold'));
      await tester.pumpAndSettle();

      // Enter amount (₹10,500)
      expect(find.text('Enter Amount or Grams'), findsOneWidget);
      await tester.enterText(find.bySemanticsLabel('Buy Amount'), '10500');
      await tester.pumpAndSettle();

      // Verify dual-conversion updated grams field to 1.3449 g
      final quantityField = tester.widget<TextField>(find.byType(TextField).last);
      expect(quantityField.controller?.text, equals('1.3449'));

      // Proceed to review
      final reviewBtn = find.text('Review Purchase');
      await tester.ensureVisible(reviewBtn);
      await tester.tap(reviewBtn);
      await tester.pumpAndSettle();

      // Verify invoice items
      expect(find.text('Invoice details'), findsOneWidget);
      expect(find.text('₹10,500.00'), findsOneWidget);

      // Confirm & Pay (triggers sheet)
      final confirmBtn = find.text('Confirm & Pay ₹10,500.00');
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify simulated Razorpay sheet is overlayed
      expect(find.text('Secure Checkout'), findsOneWidget);
      expect(find.text('Payable Amount: ₹10,500.00'), findsOneWidget);

      // Enter UPI ID and tap Pay
      await tester.enterText(find.bySemanticsLabel('UPI ID / VPA'), 'user@okaxis');
      
      // Update mocked wallet state for successful update trigger
      walletState = testWalletAfterBuy;

      final payBtn = find.text('Pay ₹10,500.00 via Simulated Razorpay');
      await tester.ensureVisible(payBtn);
      await tester.tap(payBtn);
      await tester.pumpAndSettle();

      // Verify Payment Success status page is displayed
      expect(find.text('Payment Successful'), findsOneWidget);
      expect(find.text('View Wallet Balance'), findsOneWidget);

      // Click "View Wallet Balance"
      final viewWalletBtn = find.text('View Wallet Balance');
      await tester.ensureVisible(viewWalletBtn);
      await tester.tap(viewWalletBtn);
      await tester.pumpAndSettle();

      // Verify we are navigated to Gold Wallet Screen and the balance shows 6.345 grams
      expect(find.text('Total Gold Balance'), findsOneWidget);
      expect(find.text('6.345 grams'), findsOneWidget);
    });
  });
}
