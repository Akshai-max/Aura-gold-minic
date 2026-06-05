import 'package:flutter_test/flutter_test.dart';
import 'package:aura_gold/features/auth/presentation/auth_controller.dart';
import 'package:aura_gold/features/auth/domain/app_user.dart';
import 'mocks.dart';

void main() {
  late MockAuthRepository authRepo;
  late MockSecureStorageService storage;
  late MockPreferencesService prefs;
  late AuthController controller;

  setUp(() {
    authRepo = MockAuthRepository();
    storage = MockSecureStorageService();
    prefs = MockPreferencesService();
    controller = AuthController(authRepo, storage, prefs);
  });

  group('Auth Unit Tests', () {
    test('initial state is authenticated-free', () {
      expect(controller.debugState.user, isNull);
      expect(controller.debugState.isAuthenticated, isFalse);
      expect(controller.debugState.loading, isFalse);
    });

    test('successful login updates status and stores credentials', () async {
      await controller.login(
        email: 'user@ags.com',
        password: 'User@123',
        rememberMe: true,
      );

      expect(controller.debugState.user, equals(mockUser));
      expect(controller.debugState.isAuthenticated, isTrue);
      expect(controller.debugState.error, isNull);
      
      expect(authRepo.loginCalled, isTrue);
      expect(storage.accessToken, equals('mock_access_token'));
      expect(prefs.rememberMe, isTrue);
    });

    test('failed login sets error state', () async {
      await controller.login(
        email: 'user@ags.com',
        password: 'WrongPassword',
      );

      expect(controller.debugState.user, isNull);
      expect(controller.debugState.isAuthenticated, isFalse);
      expect(controller.debugState.error, isNotNull);
    });

    test('logout clears tokens and permissions', () async {
      // Login first
      await controller.login(
        email: 'user@ags.com',
        password: 'User@123',
      );

      // Logout
      await controller.logout();

      expect(controller.debugState.user, isNull);
      expect(controller.debugState.isAuthenticated, isFalse);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(prefs.permissions, isEmpty);
      expect(authRepo.logoutCalled, isTrue);
    });

    test('restore session with valid token sets user and permissions', () async {
      storage.accessToken = 'mock_access_token';
      prefs.permissions = const ['dashboard.read'];

      await controller.restore();

      expect(controller.debugState.user, equals(mockUser));
      expect(controller.debugState.isAuthenticated, isTrue);
      expect(controller.debugState.permissions, contains('dashboard.read'));
    });

    test('restore session with expired/invalid token signs user out locally', () async {
      storage.accessToken = 'mock_access_token';
      
      // Force repo.me to fail to simulate invalid token / session expired
      authRepo = MockAuthRepositoryFailingMe();
      controller = AuthController(authRepo, storage, prefs);

      await controller.restore();

      expect(controller.debugState.user, isNull);
      expect(controller.debugState.isAuthenticated, isFalse);
      expect(storage.accessToken, isNull);
    });
  });
}

class MockAuthRepositoryFailingMe extends MockAuthRepository {
  @override
  Future<AppUser> me() async {
    throw Exception('Unauthorized');
  }
}
