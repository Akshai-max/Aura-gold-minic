import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/trading_settings_repository.dart';
import '../domain/trading_settings.dart';

final tradingSettingsProvider = FutureProvider<TradingSettings>((ref) {
  return ref.watch(tradingSettingsRepositoryProvider).getTradingSettings();
});

class TradingSettingsController extends StateNotifier<AsyncValue<TradingSettings>> {
  TradingSettingsController(this._repository) : super(const AsyncValue.loading());

  final TradingSettingsRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _repository.getTradingSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> updateSettings(TradingSettings settings) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateTradingSettings(settings);
      state = AsyncValue.data(updated);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final tradingSettingsControllerProvider =
    StateNotifierProvider<TradingSettingsController, AsyncValue<TradingSettings>>((ref) {
  final repo = ref.watch(tradingSettingsRepositoryProvider);
  final controller = TradingSettingsController(repo);
  controller.load();
  return controller;
});
