import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ags_gold/main.dart';
import 'package:ags_gold/services/service_providers.dart';
import '../test_helpers/auth_dashboard_overrides.dart';
import '../mocks/mock_services.dart';

Future<void> pumpE2eApp(
  WidgetTester tester, {
  required MockApiClient mockApi,
  required MockSecureStorage mockStorage,
}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final mockMapResponse = MockResponse<Map<String, dynamic>>();
  when(
    () => mockMapResponse.data,
  ).thenReturn({'items': [], 'total': 0, 'skip': 0, 'limit': 10});

  final mockListResponse = MockResponse<List<dynamic>>();
  when(() => mockListResponse.data).thenReturn([]);

  when(
    () => mockApi.get(
      any(),
      queryParameters: any(named: 'queryParameters'),
      options: any(named: 'options'),
      cancelToken: any(named: 'cancelToken'),
    ),
  ).thenAnswer((invocation) async {
    final path = invocation.positionalArguments[0] as String;
    if (path.contains('dashboard/metal-prices/history')) {
      final historyResponse = MockResponse<Map<String, dynamic>>();
      when(() => historyResponse.data).thenReturn({
        'metal': 'gold',
        'range': '1Y',
        'unit': 'INR/gm',
        'performance_percent': '52.48',
        'refreshed_at': DateTime.utc(2026, 6, 8).toIso8601String(),
        'points': [
          for (var i = 0; i < 12; i++)
            {
              'label': 'M${i + 1}',
              'price': (7000 + i * 40).toStringAsFixed(2),
            },
        ],
      });
      return historyResponse;
    }
    if (path.contains('dashboard/metal-prices')) {
      final metalResponse = MockResponse<Map<String, dynamic>>();
      when(() => metalResponse.data).thenReturn({
        'refreshed_at': DateTime.utc(2026, 6, 8).toIso8601String(),
        'gold': {
          'metal': 'gold',
          'unit': 'INR/gm · Tamil Nadu',
          'retail_price': '13941.84',
          'change_percent': '0.42',
          'trend': [
            for (var i = 0; i < 24; i++)
              {'label': '${i.toString().padLeft(2, '0')}:00', 'price': '7200'},
          ],
        },
        'silver': {
          'metal': 'silver',
          'unit': 'INR/gm · Tamil Nadu',
          'retail_price': '217.12',
          'change_percent': '-0.18',
          'trend': [
            for (var i = 0; i < 24; i++)
              {'label': '${i.toString().padLeft(2, '0')}:00', 'price': '90'},
          ],
        },
      });
      return metalResponse;
    }
    if (path.contains('dashboard/personal')) {
      final personalResponse = MockResponse<Map<String, dynamic>>();
      when(() => personalResponse.data).thenReturn({
        'display_name': 'E2E User',
        'email': 'user@e2e.test',
        'roles': ['user'],
        'unread_notifications': 0,
        'refreshed_at': DateTime.utc(2026, 6, 8).toIso8601String(),
        'login_statistics': {'today': 0, 'week': 0, 'month': 0},
        'activity_trend': [],
        'recent_notifications': [],
        'assigned_tasks': [],
        'daily_activities': [],
        'pending_task_count': 0,
        'draft_task_count': 0,
        'gold_savings_grams': '0',
        'silver_savings_grams': '0',
      });
      return personalResponse;
    }
    if (path.contains('audit-logs') || path.contains('dashboard/executive')) {
      if (path.contains('dashboard/executive')) {
        final executiveResponse = MockResponse<Map<String, dynamic>>();
        when(() => executiveResponse.data).thenReturn({
          'role': 'admin',
          'display_name': 'E2E User',
          'unread_notifications': 0,
          'refreshed_at': DateTime.utc(2026, 6, 8).toIso8601String(),
          'revenue_trend': [],
          'activity_trend': [],
        });
        return executiveResponse;
      }
      return mockMapResponse;
    }
    return mockListResponse;
  });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(mockApi),
          secureStorageProvider.overrideWithValue(mockStorage),
          ...authDashboardTestOverrides,
          auditLogsProvider.overrideWithValue(const AsyncValue.data([])),
        ],
        child: const AGSGoldApp(),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();
  }

Future<void> completeLogin(
  WidgetTester tester,
  MockApiClient mockApi,
  MockSecureStorage mockStorage, {
  String email = 'admin@e2e.test',
  String password = 'Password123',
}) async {
  final loginCompleter = Completer<MockResponse<Map<String, dynamic>>>();
  final mockLoginResponse = MockResponse<Map<String, dynamic>>();
  when(() => mockLoginResponse.data).thenReturn({
    'access_token': 'e2e-access-token',
    'refresh_token': 'e2e-refresh-token',
  });
  when(
    () => mockApi.post('/auth/login', data: any(named: 'data')),
  ).thenAnswer((_) => loginCompleter.future);
  when(
    () => mockStorage.saveTokens(
      accessToken: any(named: 'accessToken'),
      refreshToken: any(named: 'refreshToken'),
    ),
  ).thenAnswer((_) async {});

  await tester.enterText(find.byKey(const Key('emailField')), email);
  await tester.enterText(find.byKey(const Key('passwordField')), password);
  await tester.tap(find.byKey(const Key('loginButton')));
  loginCompleter.complete(mockLoginResponse);
  await tester.pumpAndSettle();
}
