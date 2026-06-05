import 'package:flutter/material.dart';
import 'package:aura_gold/features/auth/data/auth_repository.dart';
import 'package:aura_gold/features/auth/domain/app_user.dart';
import 'package:aura_gold/features/auth/domain/auth_session.dart';
import 'package:aura_gold/features/gold_price/data/gold_price_repository.dart';
import 'package:aura_gold/features/gold_price/domain/gold_price.dart';
import 'package:aura_gold/features/gold_price/domain/gold_settings.dart';
import 'package:aura_gold/features/gold_wallet/data/wallet_repository.dart';
import 'package:aura_gold/features/gold_wallet/domain/gold_wallet.dart';
import 'package:aura_gold/features/transactions/data/transaction_repository.dart';
import 'package:aura_gold/features/transactions/domain/ledger_transaction.dart';
import 'package:aura_gold/core/network/api_client.dart';
import 'package:aura_gold/core/storage/secure_storage_service.dart';
import 'package:aura_gold/core/storage/preferences_service.dart';
import 'package:aura_gold/features/portfolio/data/portfolio_repository.dart';
import 'package:aura_gold/features/portfolio/domain/portfolio.dart';

// --- MOCK CONSTANTS & DATA ---

final mockUser = AppUser(
  id: '9',
  firstName: 'Regular',
  lastName: 'User',
  email: 'user@ags.com',
  mobileNumber: '+919123456789',
  role: 'USER',
  isActive: true,
  emailVerified: true,
);

final mockAuthSession = AuthSession(
  accessToken: 'mock_access_token',
  refreshToken: 'mock_refresh_token',
  user: mockUser,
  permissions: const ['dashboard.read', 'profile.manage'],
);

final mockGoldPrice = GoldPrice(
  currentPrice: 7325.40,
  price24k: 7325.40,
  price22k: 6714.95,
  priceChange: 84.20,
  percentageChange: 1.16,
  todaysHigh: 7364.90,
  todaysLow: 7241.20,
  openingPrice: 7241.20,
  source: 'Mock Price Feed',
  lastUpdated: DateTime.now(),
  history: [
    const GoldPricePoint(label: '10:00 AM', price: 7241.20),
    const GoldPricePoint(label: '11:00 AM', price: 7290.00),
    const GoldPricePoint(label: '12:00 PM', price: 7325.40),
  ],
);

final mockGoldSettings = GoldSettings(
  autoPriceFeedEnabled: true,
  currentProvider: 'Mock Price Feed',
  updateFrequency: '5 minutes',
  manualOverridePrice: 0.0,
);

final mockGoldWallet = GoldWallet(
  walletId: '1',
  userId: '9',
  goldBalance: 5.235,
  availableGold: 4.100,
  lockedGold: 1.135,
  pendingGold: 0.0,
  totalInvested: 35000.0,
  currentValue: 38348.47,
  profitLoss: 3348.47,
  createdAt: DateTime.now().subtract(const Duration(days: 30)),
  updatedAt: DateTime.now(),
  isOffline: false,
);

final mockTransactionsList = [
  LedgerTransaction(
    transactionId: 't1',
    userId: '9',
    transactionType: TransactionType.buy,
    goldAmount: 1.5,
    goldPrice: 7300.0,
    amount: 10950.0,
    status: 'COMPLETED',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  LedgerTransaction(
    transactionId: 't2',
    userId: '9',
    transactionType: TransactionType.reward,
    goldAmount: 0.1,
    goldPrice: 7325.0,
    amount: 732.5,
    status: 'COMPLETED',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

final mockPortfolioSummary = PortfolioSummary(
  portfolioValue: 38348.47,
  currentPortfolioValue: 38348.47,
  investedAmount: 35000.0,
  profitLoss: 3348.47,
  percentageReturn: 9.56,
  totalGoldHoldings: 5.235,
  averagePurchasePrice: 6685.0,
  currentGoldPrice: 7325.40,
  unrealizedGainLoss: 3348.47,
  dailyChange: 120.0,
  weeklyChange: 450.0,
  monthlyChange: 1500.0,
  growth: [
    const PortfolioPoint(label: '1D', value: 38100.0),
    const PortfolioPoint(label: '2D', value: 38200.0),
    const PortfolioPoint(label: '3D', value: 38348.47),
  ],
);

// --- MOCK REPOS & SERVICES ---

class MockAuthRepository implements AuthRepository {
  bool logoutCalled = false;
  bool loginCalled = false;

  @override
  ApiClient get _api => throw UnimplementedError();

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    loginCalled = true;
    if (email == 'user@ags.com' && password == 'User@123') {
      return mockAuthSession;
    }
    throw Exception('Invalid credentials');
  }

  @override
  Future<AuthSession> register(Map<String, dynamic> data) async {
    return mockAuthSession;
  }

  @override
  Future<AppUser> me() async {
    return mockUser;
  }

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<void> resetPassword({required String token, required String password}) async {}

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

class MockWalletRepository implements WalletRepository {
  bool getWalletCalled = false;
  bool returnError = false;

  @override
  ApiClient get _api => throw UnimplementedError();

  @override
  Future<GoldWallet> getWallet() async {
    getWalletCalled = true;
    if (returnError) {
      throw Exception('Network error fetching wallet');
    }
    return mockGoldWallet;
  }
}

class MockGoldPriceRepository implements GoldPriceRepository {
  bool getPriceCalled = false;
  bool saveSettingsCalled = false;
  GoldSettings currentSettings = mockGoldSettings;

  @override
  GoldPriceRemoteDataSource get _remote => throw UnimplementedError();

  @override
  Future<GoldPrice> getGoldPrice() async {
    getPriceCalled = true;
    return mockGoldPrice;
  }

  @override
  Future<GoldSettings> getSettings() async {
    return currentSettings;
  }

  @override
  Future<GoldSettings> saveSettings(GoldSettings settings) async {
    saveSettingsCalled = true;
    currentSettings = settings;
    return currentSettings;
  }
}

class MockTransactionRepository implements TransactionRepository {
  bool getTransactionsCalled = false;
  TransactionFilter? lastFilter;

  @override
  ApiClient get _api => throw UnimplementedError();

  @override
  Future<List<LedgerTransaction>> getTransactions(TransactionFilter filter) async {
    getTransactionsCalled = true;
    lastFilter = filter;
    return mockTransactionsList;
  }
}

class MockSecureStorageService implements SecureStorageService {
  String? accessToken = 'mock_access_token';
  String? refreshToken = 'mock_refresh_token';

  @override
  dynamic get _storage => null;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}

class MockPreferencesService implements PreferencesService {
  ThemeMode themeMode = ThemeMode.dark;
  List<String> permissions = const ['dashboard.read', 'profile.manage'];
  bool rememberMe = true;

  @override
  dynamic get _preferences => null;

  @override
  ThemeMode getThemeMode() => themeMode;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
  }

  @override
  List<String> getPermissions() => permissions;

  @override
  Future<void> setPermissions(List<String> permissions) async {
    this.permissions = permissions;
  }

  @override
  bool getRememberMe() => rememberMe;

  @override
  Future<void> setRememberMe(bool value) async {
    rememberMe = value;
  }
}
