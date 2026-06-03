import 'app_user.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.permissions,
  });

  final String accessToken;
  final String refreshToken;
  final AppUser user;
  final List<String> permissions;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      permissions: (json['permissions'] as List<dynamic>).cast<String>(),
    );
  }
}
