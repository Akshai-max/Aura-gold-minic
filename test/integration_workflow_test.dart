import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_gold/main.dart';
import 'package:aura_gold/features/auth/presentation/auth_controller.dart';
import 'package:aura_gold/features/gold_wallet/data/wallet_repository.dart';
import 'package:aura_gold/features/gold_price/data/gold_price_repository.dart';
import 'package:aura_gold/features/portfolio/data/portfolio_repository.dart';
import 'package:aura_gold/features/transactions/data/transaction_repository.dart';
import 'package:aura_gold/core/storage/preferences_service.dart';

import 'mocks.dart';

// Stub class for AuthController starting in logged out state
class MockIntegrationAuthController extends AuthController {
  MockIntegrationAuthController()
      : super(MockAuthRepository(), MockSecureStorageService(), MockPreferencesService()) {
    state = const AuthState(); // Logged out initial state
  }

  set debugState(AuthState nextState) {
    state = nextState;
  }

  @override
  Future<void> restore() async {}
}

void main() {
  late MockIntegrationAuthController mockAuthController;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppBootstrapCache.preferences = await SharedPreferences.getInstance();
    mockAuthController = MockIntegrationAuthController();
  });

  group('Integration Workflow E2E Tests', () {
    testWidgets('User workflow: Login -> Dashboard -> Wallet -> Portfolio -> Transactions', (WidgetTester tester) async {
      // 1. Pump AuraGoldApp with Mock Repository Overrides
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) => mockAuthController),
            walletProvider.overrideWith((ref) => mockGoldWallet),
            portfolioProvider.overrideWith((ref) => mockPortfolioSummary),
            goldPriceProvider.overrideWith((ref) => mockGoldPrice),
            transactionProvider.overrideWith((ref) => mockTransactionsList),
          ],
          child: const AuraGoldApp(),
        ),
      );
      await tester.pumpAndSettle();

      // --- LOGIN PAGE ---
      // Verify Login Screen is displayed since the user is not authenticated
      expect(find.text('Secure platform access'), findsOneWidget);

      // Enter login credentials
      await tester.enterText(find.bySemanticsLabel('Email address'), 'user@ags.com');
      await tester.enterText(find.bySemanticsLabel('Password'), 'User@123');
      await tester.tap(find.text('SIGN IN'));
      
      // Simulate successful auth state transition
      mockAuthController.debugState = AuthState(
        user: mockUser,
        permissions: const ['dashboard.read', 'profile.manage'],
      );
      await tester.pumpAndSettle();

      // --- DASHBOARD SCREEN ---
      // Verify we navigated to the Dashboard
      expect(find.text('Welcome, Regular'), findsOneWidget);
      expect(find.text('Total Portfolio Value'), findsOneWidget);

      // --- DRAWER NAVIGATION TO WALLET ---
      // Open navigation drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      // Tap Wallet in Drawer
      await tester.tap(find.descendant(
        of: find.byType(NavigationDrawer),
        matching: find.text('Wallet'),
      ));
      await tester.pumpAndSettle();

      // Verify Wallet Screen is loaded
      expect(find.text('Total Gold Balance'), findsOneWidget);
      expect(find.text('5.235 grams'), findsOneWidget);

      // --- DRAWER NAVIGATION TO PORTFOLIO ---
      state.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(NavigationDrawer),
        matching: find.text('Portfolio'),
      ));
      await tester.pumpAndSettle();

      // Verify Portfolio Screen is loaded
      expect(find.text('Portfolio Statistics'), findsOneWidget);
      expect(find.text('₹38,348.47'), findsNWidgets(3)); // Updates to match triple occurrences

      // --- DRAWER NAVIGATION TO TRANSACTIONS ---
      state.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(NavigationDrawer),
        matching: find.text('Transactions'),
      ));
      await tester.pumpAndSettle();

      // Verify Transactions Screen is loaded
      expect(find.text('Buy Gold'), findsOneWidget);
      expect(find.text('Gold Reward'), findsOneWidget);
    });
  });
}
