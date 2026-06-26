import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ags_gold/features/user_dashboard/domain/personal_dashboard.dart';
import 'package:ags_gold/services/service_providers.dart';

const _pollInterval = Duration(seconds: 30);

final personalDashboardProvider =
    AsyncNotifierProvider.autoDispose<PersonalDashboardNotifier, PersonalDashboard>(
  PersonalDashboardNotifier.new,
);

class PersonalDashboardNotifier extends AsyncNotifier<PersonalDashboard> {
  Timer? _pollTimer;

  @override
  Future<PersonalDashboard> build() async {
    ref.onDispose(() => _pollTimer?.cancel());

    final auth = await ref.watch(authNotifierProvider.future);
    if (auth != AuthStatus.authenticated) {
      throw StateError('Not authenticated');
    }

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(refresh(silent: true));
    });

    return _fetch();
  }

  Future<PersonalDashboard> _fetch() async {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get('/dashboard/personal');
    return PersonalDashboard.fromJson(response.data as Map<String, dynamic>);
  }

  /// Reload dashboard from the server. Use after payments or other balance changes.
  Future<void> refresh({bool silent = false}) async {
    if (!ref.mounted) return;
    if (!silent) {
      state = const AsyncValue.loading();
    }
    state = await AsyncValue.guard(_fetch);
  }
}
