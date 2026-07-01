import 'package:ags_gold/features/app_update/domain/android_app_release.dart';
import 'package:ags_gold/services/api_client.dart';
import 'package:dio/dio.dart';

class AppUpdateRepository {
  AppUpdateRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AndroidAppRelease?> fetchAndroidRelease() async {
    try {
      final response = await _apiClient.get('/app/android-release');
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      return AndroidAppRelease.fromJson(data);
    } on NotFoundException {
      return null;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
