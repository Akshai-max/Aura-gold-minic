import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/app_user.dart';
import '../domain/auth_session.dart';

class AuthEndpoints {
  const AuthEndpoints._();

  static const login = '/auth/login';
  static const register = '/auth/register';
  static const refresh = '/auth/refresh';
  static const logout = '/auth/logout';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const verifyEmail = '/auth/verify-email';
  static const me = '/auth/me';
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      AuthEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return AuthSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthSession> register(Map<String, dynamic> data) async {
    final response = await _api.post(AuthEndpoints.register, data: data);
    return AuthSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AppUser> me() async {
    final response = await _api.get(AuthEndpoints.me);
    return AppUser.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> forgotPassword(String email) async {
    await _api.post(AuthEndpoints.forgotPassword, data: {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _api.post(
      AuthEndpoints.resetPassword,
      data: {'token': token, 'password': password},
    );
  }

  Future<void> logout() async {
    await _api.post(AuthEndpoints.logout);
  }
}
