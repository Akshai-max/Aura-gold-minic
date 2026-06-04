import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:aura_gold/features/gold_wallet/data/wallet_repository.dart';
import 'package:aura_gold/core/storage/preferences_service.dart';
import 'package:aura_gold/core/network/api_client.dart';
import 'mocks.dart';

class MockApiClient extends Fake implements ApiClient {
  bool fail = false;
  Map<String, dynamic> data = const {};

  @override
  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    if (fail) throw Exception('API Error');
    return Response(
      requestOptions: RequestOptions(path: path),
      data: data,
      statusCode: 200,
    );
  }
}

void main() {
  late MockApiClient mockApi;
  late WalletRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppBootstrapCache.preferences = await SharedPreferences.getInstance();
    mockApi = MockApiClient();
    repository = WalletRepository(mockApi);
  });

  group('Wallet Unit Tests', () {
    final walletJson = {
      'wallet_id': 1,
      'user_id': 9,
      'gold_balance': '5.235',
      'available_gold': '4.100',
      'locked_gold': '1.135',
      'pending_gold': '0.0',
      'total_invested': '35000.0',
      'current_value': '38348.47',
      'profit_loss': '3348.47',
      'created_at': '2026-06-04T10:00:00Z',
      'updated_at': '2026-06-04T10:00:00Z',
    };

    test('successful network fetch updates local cache', () async {
      mockApi.data = walletJson;

      final wallet = await repository.getWallet();

      expect(wallet.goldBalance, equals(5.235));
      expect(wallet.isOffline, isFalse);

      // Verify cached values
      final cachedStr = AppBootstrapCache.preferences.getString('cached_gold_wallet');
      expect(cachedStr, isNotNull);
      final cachedJson = jsonDecode(cachedStr!) as Map<String, dynamic>;
      expect(cachedJson['gold_balance'], equals('5.235'));
    });

    test('network failure triggers cache fallback if cache exists', () async {
      // Seed cache first
      await AppBootstrapCache.preferences.setString('cached_gold_wallet', jsonEncode(walletJson));

      // Set API to fail
      mockApi.fail = true;

      final wallet = await repository.getWallet();

      expect(wallet.goldBalance, equals(5.235));
      expect(wallet.isOffline, isTrue); // verified offline state fallback
    });

    test('network failure throws exception if no cache exists', () async {
      mockApi.fail = true;

      expect(repository.getWallet(), throwsA(isA<Exception>()));
    });
  });
}
