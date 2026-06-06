import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ags_gold/config/env_config.dart';
import 'package:ags_gold/services/interfaces/secure_storage.dart';
import 'package:ags_gold/services/secure_storage_service.dart';
import 'package:ags_gold/services/api_client.dart';

// Authentication Status Options
enum AuthStatus { initial, authenticated, unauthenticated }

class AuthNotifier extends AsyncNotifier<AuthStatus> {
  late final ISecureStorage _storage;

  @override
  FutureOr<AuthStatus> build() async {
    _storage = ref.watch(secureStorageProvider);
    // Artificial delay to make the splash screen visible
    await Future.delayed(const Duration(seconds: 2));
    final hasToken = await _storage.hasAccessToken();
    return hasToken ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  }

  Future<void> login(String token) async {
    state = const AsyncValue.loading();
    try {
      await _storage.saveTokens(
        accessToken: token,
        refreshToken: 'refresh-token-placeholder',
      );
      state = const AsyncValue.data(AuthStatus.authenticated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _storage.clearTokens();
      state = const AsyncValue.data(AuthStatus.unauthenticated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Provides environment config parameters
final envConfigProvider = Provider<EnvConfig>((ref) {
  return EnvConfig.active;
});

// Provides Secure Storage service
final secureStorageProvider = Provider<ISecureStorage>((ref) {
  return SecureStorageService();
});

// Provides ApiClient instance injected with SecureStorage interface
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final env = ref.watch(envConfigProvider);
  return ApiClient(storageService: storage, config: env);
});

// Provides current authentication state using AsyncNotifierProvider
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthStatus>(
  AuthNotifier.new,
);
