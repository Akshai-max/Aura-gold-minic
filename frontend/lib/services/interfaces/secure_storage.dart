abstract class ISecureStorage {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<void> clearTokens();

  Future<bool> hasAccessToken();
}
