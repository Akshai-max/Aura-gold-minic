import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/trading_settings.dart';

final tradingSettingsRepositoryProvider = Provider<TradingSettingsRepository>((ref) {
  return TradingSettingsRepository(ref.watch(apiClientProvider));
});

class TradingSettingsRepository {
  TradingSettingsRepository(this._api);

  final ApiClient _api;

  Future<TradingSettings> getTradingSettings() async {
    final response = await _api.get('/trading-settings');
    return TradingSettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TradingSettings> updateTradingSettings(TradingSettings settings) async {
    final response = await _api.put(
      '/trading-settings',
      data: settings.toJson(),
    );
    return TradingSettings.fromJson(response.data as Map<String, dynamic>);
  }
}
