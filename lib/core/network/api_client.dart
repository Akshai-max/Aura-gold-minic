import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../features/auth/data/auth_repository.dart';
import '../storage/secure_storage_service.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.addAll([
    AuthInterceptor(storage),
    TokenInterceptor(dio, storage),
    ErrorInterceptor(),
  ]);
  return dio;
});

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _dio.get(path, queryParameters: query);
  }

  Future<Response<dynamic>> post(String path, {Object? data}) {
    return _dio.post(path, data: data);
  }

  Future<Response<dynamic>> put(String path, {Object? data}) {
    return _dio.put(path, data: data);
  }

  Future<Response<dynamic>> delete(String path) => _dio.delete(path);
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final SecureStorageService _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class TokenInterceptor extends Interceptor {
  TokenInterceptor(this._dio, this._storage);

  final Dio _dio;
  final SecureStorageService _storage;
  Future<void>? _refreshFuture;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 ||
        err.requestOptions.path == AuthEndpoints.refresh) {
      return handler.next(err);
    }

    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) {
      await _storage.clearTokens();
      return handler.next(err);
    }

    try {
      _refreshFuture ??= _performRefresh(refreshToken);
      await _refreshFuture;
    } catch (_) {
      await _storage.clearTokens();
      return handler.next(err);
    } finally {
      _refreshFuture = null;
    }

    try {
      final accessToken = await _storage.getAccessToken();
      if (accessToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $accessToken';
      }
      final retry = await _dio.fetch<dynamic>(err.requestOptions);
      return handler.resolve(retry);
    } catch (e) {
      return handler.next(err);
    }
  }

  Future<void> _performRefresh(String refreshToken) async {
    final response = await _dio.post(
      AuthEndpoints.refresh,
      data: {'refresh_token': refreshToken},
      options: Options(headers: {'Authorization': null}),
    );
    final data = response.data as Map<String, dynamic>;
    await _storage.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
