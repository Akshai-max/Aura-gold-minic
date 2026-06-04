import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/preferences_service.dart';
import '../domain/gold_wallet.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(apiClientProvider));
});

final walletProvider = FutureProvider<GoldWallet>((ref) {
  return ref.watch(walletRepositoryProvider).getWallet();
});

class WalletRepository {
  WalletRepository(this._api);

  final ApiClient _api;
  static const _cacheKey = 'cached_gold_wallet';

  Future<GoldWallet> getWallet() async {
    try {
      final response = await _api.get('/wallet');
      final data = response.data as Map<String, dynamic>;
      
      // Save to cache
      try {
        await AppBootstrapCache.preferences.setString(_cacheKey, jsonEncode(data));
      } catch (_) {}
      
      return GoldWallet.fromJson(data);
    } catch (e) {
      // Fallback to offline cache
      try {
        final cached = AppBootstrapCache.preferences.getString(_cacheKey);
        if (cached != null) {
          final data = jsonDecode(cached) as Map<String, dynamic>;
          return GoldWallet.fromJson({
            ...data,
            'is_offline': true,
          });
        }
      } catch (_) {}
      
      rethrow;
    }
  }
}
