import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_gold/features/auth/presentation/auth_controller.dart';
import 'package:aura_gold/features/dashboard/presentation/dashboard_screen.dart';
import 'package:aura_gold/features/gold_wallet/presentation/gold_wallet_screen.dart';
import 'package:aura_gold/features/gold_wallet/data/wallet_repository.dart';
import 'package:aura_gold/features/gold_price/presentation/gold_price_widgets.dart';
import 'package:aura_gold/features/gold_price/data/gold_price_repository.dart';
import 'package:aura_gold/features/portfolio/presentation/portfolio_screen.dart';
import 'package:aura_gold/features/portfolio/data/portfolio_repository.dart';
import 'package:aura_gold/features/portfolio/domain/portfolio.dart';
import 'package:aura_gold/features/transactions/presentation/transaction_history_screen.dart';
import 'package:aura_gold/features/transactions/data/transaction_repository.dart';

import 'mocks.dart';

// Stub class for AuthController
class MockWidgetAuthController extends AuthController {
  MockWidgetAuthController()
      : super(MockAuthRepository(), MockSecureStorageService(), MockPreferencesService()) {
    state = AuthState(
      user: mockUser,
      permissions: const ['dashboard.read', 'profile.manage'],
    );
  }

  @override
  Future<void> restore() async {}
}
void main() {
  late MockWidgetAuthController mockAuthController;

  setUp(() {
    mockAuthController = MockWidgetAuthController();
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => mockAuthController),
        walletProvider.overrideWith((ref) => mockGoldWallet),
        portfolioProvider.overrideWith((ref) => mockPortfolioSummary),
        goldPriceProvider.overrideWith((ref) => mockGoldPrice),
        transactionProvider.overrideWith((ref) => mockTransactionsList),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('Widget UI Tests', () {
    testWidgets('DashboardScreen renders portfolio hero card, wallet card and live gold widget', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const DashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Total Portfolio Value'), findsOneWidget);
      expect(find.text('₹38,348.47'), findsOneWidget);
      expect(find.text('Live Gold Price'), findsOneWidget);
      expect(find.text('₹7,325.40 / g'), findsOneWidget);
      expect(find.text('Gold Wallet'), findsOneWidget);
      expect(find.text('5.235 g'), findsOneWidget);
    });

    testWidgets('GoldWalletScreen renders balance, linear progress and individual gold balance pills', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const GoldWalletScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Total Gold Balance'), findsOneWidget);
      expect(find.text('5.235 grams'), findsOneWidget);
      expect(find.text('Available Gold'), findsOneWidget);
      expect(find.text('4.100 g'), findsOneWidget);
      expect(find.text('Locked Gold'), findsOneWidget);
      expect(find.text('1.135 g'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('PortfolioScreen renders interactive area chart, filters and stats card', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const PortfolioScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Current Value'), findsNWidgets(2));
      expect(find.text('₹38,348.47'), findsNWidgets(3));
      expect(find.text('Portfolio Statistics'), findsOneWidget);
      expect(find.text('Average Buy Price'), findsOneWidget);
      expect(find.text('₹6,685.00 / g'), findsOneWidget);
      expect(find.byType(InteractivePortfolioChart), findsOneWidget);
    });

    testWidgets('GoldPriceDetailsScreen renders Live Price Card, Sparkline and Market Stats', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const GoldPriceDetailsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Live Gold Rate'), findsOneWidget);
      expect(find.text('₹7,325.40 / g'), findsNWidgets(2));
      expect(find.text('24 Karats (Pure)'), findsOneWidget);
      expect(find.text('Market Statistics'), findsOneWidget);
      expect(find.text('Opening Price'), findsOneWidget);
      expect(find.text('₹7,241.20'), findsNWidgets(2));
    });

    testWidgets('TransactionHistoryScreen renders transaction cards and badges', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const TransactionHistoryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Buy Gold'), findsOneWidget);
      expect(find.text('Gold Reward'), findsOneWidget);
      expect(find.text('₹10,950.00'), findsOneWidget);
      expect(find.text('₹732.50'), findsOneWidget);
      expect(find.text('Completed'), findsNWidgets(2));
    });
  });
}
