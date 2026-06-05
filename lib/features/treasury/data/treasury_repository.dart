import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/gold_treasury.dart';

final treasuryRepositoryProvider = Provider<TreasuryRepository>((ref) {
  return TreasuryRepository(ref.watch(apiClientProvider));
});

class TreasuryRepository {
  TreasuryRepository(this._api);

  final ApiClient _api;

  Future<GoldTreasury> getTreasury() async {
    final response = await _api.get('/treasury');
    return GoldTreasury.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GoldTreasury> updateTreasury(double availableGold) async {
    final response = await _api.put(
      '/treasury',
      data: {'available_gold': availableGold},
    );
    return GoldTreasury.fromJson(response.data as Map<String, dynamic>);
  }
}
