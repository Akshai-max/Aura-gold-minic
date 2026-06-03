import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_session.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      ref.watch(authRepositoryProvider),
      ref.watch(secureStorageProvider),
      ref.watch(preferencesServiceProvider),
    )..restore();
  },
);

class AuthState {
  const AuthState({
    this.user,
    this.permissions = const [],
    this.loading = false,
    this.error,
  });

  final AppUser? user;
  final List<String> permissions;
  final bool loading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    List<String>? permissions,
    bool? loading,
    String? error,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      permissions: permissions ?? this.permissions,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._storage, this._preferences)
    : super(const AuthState());

  final AuthRepository _repository;
  final SecureStorageService _storage;
  final PreferencesService _preferences;

  Future<void> restore() async {
    final token = await _storage.getAccessToken();
    if (token == null) return;
    try {
      final user = await _repository.me();
      state = state.copyWith(
        user: user,
        permissions: _preferences.getPermissions(),
      );
    } catch (_) {
      await logout(localOnly: true);
    }
  }

  Future<void> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    await _runAuthAction(() async {
      final session = await _repository.login(email: email, password: password);
      await _applySession(session);
      await _preferences.setRememberMe(rememberMe);
    });
  }

  Future<void> register(Map<String, dynamic> data) async {
    await _runAuthAction(() async {
      final session = await _repository.register(data);
      await _applySession(session);
    });
  }

  Future<void> logout({bool localOnly = false}) async {
    if (!localOnly) {
      try {
        await _repository.logout();
      } catch (_) {}
    }
    await _storage.clearTokens();
    await _preferences.setPermissions(const []);
    state = const AuthState();
  }

  Future<void> _applySession(AuthSession session) async {
    await _storage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    await _preferences.setPermissions(session.permissions);
    state = state.copyWith(
      user: session.user,
      permissions: session.permissions,
      loading: false,
    );
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    state = state.copyWith(loading: true);
    try {
      await action();
      state = state.copyWith(loading: false);
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }
}
