import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/treasury_repository.dart';
import '../domain/gold_treasury.dart';

final treasuryProvider = FutureProvider<GoldTreasury>((ref) async {
  return ref.watch(treasuryRepositoryProvider).getTreasury();
});

class TreasuryController extends StateNotifier<AsyncValue<GoldTreasury?>> {
  TreasuryController(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final TreasuryRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.getTreasury);
  }

  Future<bool> updateAvailableGold(double availableGold) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateTreasury(availableGold);
      state = AsyncValue.data(updated);
      return true;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      return false;
    }
  }
}

final treasuryControllerProvider =
    StateNotifierProvider<TreasuryController, AsyncValue<GoldTreasury?>>((ref) {
  return TreasuryController(ref.watch(treasuryRepositoryProvider));
});
