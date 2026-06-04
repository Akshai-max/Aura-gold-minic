import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_gold/features/auth/presentation/auth_controller.dart';
import 'package:aura_gold/features/buy_gold/presentation/buy_gold_screen.dart';
import 'package:aura_gold/features/buy_gold/presentation/buy_review_screen.dart';
import 'package:aura_gold/features/sell_gold/presentation/sell_gold_screen.dart';
import 'package:aura_gold/features/sell_gold/presentation/sell_review_screen.dart';
import 'package:aura_gold/features/orders/presentation/order_history_screen.dart';
import 'package:aura_gold/features/orders/domain/order.dart';
import 'package:aura_gold/features/orders/providers/order_provider.dart';
import 'package:aura_gold/features/payments/presentation/payment_status_screen.dart';
import 'package:aura_gold/features/transaction_details/presentation/transaction_details_screen.dart';
import 'package:aura_gold/features/settings/presentation/admin_trading_settings_screen.dart';
import 'package:aura_gold/features/settings/providers/trading_settings_provider.dart';
import 'package:aura_gold/features/settings/domain/trading_settings.dart';
import 'package:aura_gold/features/settings/data/trading_settings_repository.dart';
import 'package:aura_gold/features/gold_price/data/gold_price_repository.dart';
import 'package:aura_gold/features/gold_wallet/data/wallet_repository.dart';

import 'mocks.dart';

class FakeTradingSettingsRepository implements TradingSettingsRepository {
  @override
  dynamic get _api => null;

  @override
  Future<TradingSettings> getTradingSettings() async {
    return const TradingSettings(
      buyMargin: 1.5,
      sellMargin: 1.0,
      dailyLimit: 100000.0,
      minimumPurchaseAmount: 10.0,
      maximumPurchaseAmount: 50000.0,
      tradingEnabled: true,
    );
  }

  @override
  Future<TradingSettings> updateTradingSettings(TradingSettings settings) async {
    return settings;
  }
}

class MockWidgetAuthController extends AuthController {
  MockWidgetAuthController()
      : super(MockAuthRepository(), MockSecureStorageService(), MockPreferencesService()) {
    state = AuthState(
      user: mockUser,
      permissions: const ['dashboard.read', 'profile.manage'],
    );
  }
}

void main() {
  late MockWidgetAuthController mockAuthController;

  final testTradingSettings = const TradingSettings(
    buyMargin: 1.5,
    sellMargin: 1.0,
    dailyLimit: 100000.0,
    minimumPurchaseAmount: 10.0,
    maximumPurchaseAmount: 50000.0,
    tradingEnabled: true,
  );

  final testOrder = OrderModel(
    id: 123,
    userId: 9,
    orderType: OrderType.buy,
    goldQuantity: 1.25,
    price: 7435.28,
    amount: 9294.10,
    fees: 185.88,
    taxes: 278.82,
    status: OrderStatus.completed,
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockAuthController = MockWidgetAuthController();
  });

  Widget buildTestableWidget(Widget child) {
    final fakeRepo = FakeTradingSettingsRepository();
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => mockAuthController),
        walletProvider.overrideWith((ref) => mockGoldWallet),
        goldPriceProvider.overrideWith((ref) => mockGoldPrice),
        tradingSettingsRepositoryProvider.overrideWithValue(fakeRepo),
        tradingSettingsProvider.overrideWith((ref) async => testTradingSettings),
        tradingSettingsControllerProvider.overrideWith((ref) {
          final notifier = TradingSettingsController(fakeRepo);
          notifier.state = AsyncValue.data(testTradingSettings);
          return notifier;
        }),
        ordersProvider.overrideWith((ref) async => [testOrder]),
        orderDetailsProvider(123).overrideWith((ref) async => testOrder),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Trading Flow Widget UI Tests', () {
    testWidgets('BuyGoldScreen renders input fields and live rate', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const BuyGoldScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Buy Gold'), findsOneWidget);
      expect(find.text('Live Purchase Rate (incl. margin)'), findsOneWidget);
      expect(find.text('Buy Amount'), findsOneWidget);
      expect(find.text('Gold Quantity'), findsOneWidget);
      expect(find.text('Review Purchase'), findsOneWidget);
    });

    testWidgets('BuyReviewScreen renders full invoice breakdown', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const BuyReviewScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Invoice details'), findsOneWidget);
      expect(find.text('Base Gold Cost'), findsOneWidget);
      expect(find.text('Processing Fees (2%)'), findsOneWidget);
      expect(find.text('GST / Taxes (3%)'), findsOneWidget);
      expect(find.text('Net Payable Amount'), findsOneWidget);
    });

    testWidgets('SellGoldScreen renders available balance and live rate', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const SellGoldScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Available Gold Balance'), findsOneWidget);
      expect(find.text('Sell Max'), findsOneWidget);
      expect(find.text('Live Selling Rate (incl. margin deduction)'), findsOneWidget);
      expect(find.text('Payout Amount'), findsOneWidget);
    });

    testWidgets('SellReviewScreen renders sell breakdown', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const SellReviewScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Transaction breakdown'), findsOneWidget);
      expect(find.text('Grams Selling'), findsOneWidget);
      expect(find.text('Selling Price / Rate'), findsOneWidget);
      expect(find.text('Instant Bank/Wallet Payout'), findsOneWidget);
    });

    testWidgets('PaymentStatusScreen renders receipt card and status info', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(PaymentStatusScreen(
        order: testOrder,
        success: true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Payment Successful'), findsOneWidget);
      expect(find.text('Transaction Summary'), findsOneWidget);
      expect(find.text('Order ID'), findsOneWidget);
      expect(find.text('#123'), findsOneWidget);
      expect(find.text('View Wallet Balance'), findsOneWidget);
    });

    testWidgets('OrderHistoryScreen renders list of orders with badges', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const OrderHistoryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Trading History'), findsOneWidget);
      expect(find.text('Your Buy & Sell Orders'), findsOneWidget);
      expect(find.text('Buy Gold'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
    });

    testWidgets('TransactionDetailsScreen renders vertical status timeline', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const TransactionDetailsScreen(orderId: 123)));
      await tester.pumpAndSettle();

      expect(find.text('Order Progress Timeline'), findsOneWidget);
      expect(find.text('Order Created'), findsOneWidget);
      expect(find.text('Razorpay Payment Checkout'), findsOneWidget);
      expect(find.text('Gold Deposited to Wallet'), findsOneWidget);
    });

    testWidgets('AdminTradingSettingsScreen renders forms and global switch', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const AdminTradingSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Configure Trading Engine'), findsOneWidget);
      expect(find.text('Enable Trading Workflow'), findsOneWidget);
      expect(find.text('Trading Margins (%)'), findsOneWidget);
      expect(find.text('Purchase Caps & Thresholds (₹)'), findsOneWidget);
      expect(find.text('Save Configuration'), findsOneWidget);
    });
  });
}
