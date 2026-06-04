import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../core/network/api_client.dart';
import '../domain/gold_price.dart';
import '../domain/gold_settings.dart';

class GoldPriceEndpoints {
  const GoldPriceEndpoints._();

  static const price = '/gold-price';
  static const settings = '/gold-price/settings';
}

abstract class GoldPriceRemoteDataSource {
  Future<GoldPrice> fetchPrice();
  Future<GoldSettings> fetchSettings();
  Future<GoldSettings> updateSettings(GoldSettings settings);
}

class ApiGoldPriceRemoteDataSource implements GoldPriceRemoteDataSource {
  ApiGoldPriceRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<GoldPrice> fetchPrice() async {
    final response = await _api.get(GoldPriceEndpoints.price);
    return GoldPrice.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<GoldSettings> fetchSettings() async {
    final response = await _api.get(GoldPriceEndpoints.settings);
    return GoldSettings.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<GoldSettings> updateSettings(GoldSettings settings) async {
    final response = await _api.put(
      GoldPriceEndpoints.settings,
      data: settings.toJson(),
    );
    return GoldSettings.fromJson(response.data as Map<String, dynamic>);
  }
}

final goldPriceRemoteDataSourceProvider = Provider<GoldPriceRemoteDataSource>((
  ref,
) {
  return ApiGoldPriceRemoteDataSource(ref.watch(apiClientProvider));
});

final goldPriceRepositoryProvider = Provider<GoldPriceRepository>((ref) {
  return GoldPriceRepository(ref.watch(goldPriceRemoteDataSourceProvider));
});
final goldPriceProvider = FutureProvider<GoldPrice>((ref) {
  final repository = ref.watch(goldPriceRepositoryProvider);
  final settingsAsync = ref.watch(goldSettingsProvider);

  settingsAsync.whenData((settings) {
    if (settings.autoPriceFeedEnabled) {
      final frequency = settings.updateFrequency;
      final duration = _parseFrequency(frequency);
      final timer = Timer(duration, () {
        ref.invalidateSelf();
      });
      ref.onDispose(() => timer.cancel());
    }
  });

  return repository.getGoldPrice();
});

Duration _parseFrequency(String value) {
  final clean = value.toLowerCase().trim();
  if (clean.contains('1 minute')) return const Duration(minutes: 1);
  if (clean.contains('5 minutes')) return const Duration(minutes: 5);
  if (clean.contains('15 minutes')) return const Duration(minutes: 15);
  if (clean.contains('1 hour')) return const Duration(hours: 1);
  return const Duration(minutes: 5);
}

final goldSettingsProvider = FutureProvider<GoldSettings>((ref) {
  return ref.watch(goldPriceRepositoryProvider).getSettings();
});

class GoldPriceService {
  GoldPriceService(this._repository);

  final GoldPriceRepository _repository;

  Future<GoldPrice> currentPrice() => _repository.getGoldPrice();
}

class GoldPriceRepository {
  GoldPriceRepository(this._remote);

  final GoldPriceRemoteDataSource _remote;

  Future<GoldPrice> getGoldPrice() => _remote.fetchPrice();

  Future<GoldSettings> getSettings() => _remote.fetchSettings();

  Future<GoldSettings> saveSettings(GoldSettings settings) =>
      _remote.updateSettings(settings);
}
