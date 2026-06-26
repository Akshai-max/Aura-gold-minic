import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ags_gold/features/auth/presentation/signup_screen.dart';
import 'package:ags_gold/features/user_dashboard/presentation/user_dashboard_screen.dart';
import 'package:ags_gold/main.dart';
import 'package:ags_gold/services/service_providers.dart';
import '../mocks/mock_services.dart';
import '../test_helpers/auth_dashboard_overrides.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SignupScreen renders registration form', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SignupScreen()),
      ),
    );

    expect(find.byKey(const Key('signupButton')), findsOneWidget);
    expect(find.byKey(const Key('verifyMobileButton')), findsOneWidget);
    expect(find.byKey(const Key('verifyOtpButton')), findsOneWidget);
    expect(find.byKey(const Key('otpField')), findsOneWidget);
    expect(find.byKey(const Key('goToLoginLink')), findsOneWidget);
  });

  testWidgets('User flow: login lands on user dashboard', (tester) async {
    final mockApi = MockApiClient();
    final mockStorage = MockSecureStorage();

    when(() => mockStorage.hasAccessToken()).thenAnswer((_) async => false);
    when(
      () => mockStorage.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {});

    final mockLoginResponse = MockResponse<Map<String, dynamic>>();
    when(() => mockLoginResponse.data).thenReturn({
      'access_token': 'user-access-token',
      'refresh_token': 'user-refresh-token',
    });
    when(
      () => mockApi.post('/auth/login/mobile', data: any(named: 'data')),
    ).thenAnswer((_) async => mockLoginResponse);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(mockApi),
          secureStorageProvider.overrideWithValue(mockStorage),
          ...userDashboardTestOverrides,
        ],
        child: const AGSGoldApp(),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    if (find.byKey(const Key('endUserCard')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('endUserCard')));
      await tester.pumpAndSettle();
    }

    if (find.byKey(const Key('goToLoginLink')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('goToLoginLink')));
      await tester.pumpAndSettle();
    }

    await tester.enterText(
      find.byKey(const Key('mobileField')),
      '9876543210',
    );
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(find.byType(UserDashboardScreen), findsOneWidget);
  });
}
