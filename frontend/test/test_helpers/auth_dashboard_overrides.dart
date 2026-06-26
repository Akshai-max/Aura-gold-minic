import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ags_gold/features/auth/domain/app_audience.dart';
import 'package:ags_gold/features/auth/presentation/providers/app_audience_provider.dart';
import 'package:ags_gold/features/dashboard/domain/dashboard_stats.dart';
import 'package:ags_gold/features/dashboard/domain/executive_dashboard.dart';
import 'package:ags_gold/features/dashboard/presentation/providers/executive_dashboard_provider.dart';
import 'package:ags_gold/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:ags_gold/features/profile/domain/profile.dart';
import 'package:ags_gold/features/user_dashboard/domain/personal_dashboard.dart';
import 'package:ags_gold/features/user_dashboard/domain/metal_prices.dart';
import 'package:ags_gold/features/user_dashboard/presentation/providers/metal_prices_provider.dart';
import 'metal_price_fixtures.dart';
import 'package:ags_gold/features/user_dashboard/presentation/providers/personal_dashboard_provider.dart';
import 'package:ags_gold/services/service_providers.dart';

class _FixedAudienceNotifier extends AppAudienceNotifier {
  _FixedAudienceNotifier(this.audience);

  final AppAudience audience;

  @override
  AppAudience? build() => audience;
}

class FixedPersonalDashboardNotifier extends PersonalDashboardNotifier {
  FixedPersonalDashboardNotifier(this._dashboard);

  final PersonalDashboard _dashboard;

  @override
  Future<PersonalDashboard> build() async => _dashboard;

  @override
  Future<void> refresh({bool silent = false}) async {}
}

final dashboardTestProfile = UserProfile(
  id: '11111111-1111-1111-1111-111111111111',
  email: 'test@agsgold.com',
  firstName: 'Test',
  lastName: 'User',
  isActive: true,
  isSuperuser: true,
  createdAt: DateTime.utc(2026, 6, 8),
  updatedAt: DateTime.utc(2026, 6, 8),
);

ExecutiveDashboard dashboardTestExecutive({String role = 'admin'}) {
  return ExecutiveDashboard(
    role: role,
    displayName: 'Test User',
    unreadNotifications: 0,
    refreshedAt: DateTime.utc(2026, 6, 8, 10),
  );
}

PersonalDashboard dashboardTestPersonal() {
  return PersonalDashboard(
    displayName: 'Test User',
    email: 'test@agsgold.com',
    roles: const ['user'],
    unreadNotifications: 0,
    refreshedAt: DateTime.utc(2026, 6, 8, 10),
    loginStatistics: const LoginStatistics(today: 0, week: 0, month: 0),
  );
}

MetalPrices dashboardTestMetalPrices() {
  final trend = List.generate(
    24,
    (i) => MetalPricePoint(
      label: '${i.toString().padLeft(2, '0')}:00',
      price: 7200.0 + i,
    ),
  );
  return MetalPrices(
    refreshedAt: DateTime.utc(2026, 6, 8, 10),
    gold: mockMetalQuote(
      metal: MetalType.gold,
      spotPrice: 7285,
      changePercent: 0.5,
      trend: trend,
    ),
    silver: mockMetalQuote(
      metal: MetalType.silver,
      spotPrice: 92.5,
      changePercent: -0.2,
      trend: trend,
    ),
  );
}

/// Shared provider overrides for auth flows that land on the staff dashboard.
final authDashboardTestOverrides = [
  appAudienceProvider.overrideWith(
    () => _FixedAudienceNotifier(AppAudience.staffAdmin),
  ),
  profileProvider.overrideWith((ref) async => dashboardTestProfile),
  executiveDashboardProvider.overrideWith(
    (ref) => Stream.value(dashboardTestExecutive()),
  ),
  unreadNotificationsCountProvider.overrideWithValue(
    const AsyncValue.data(0),
  ),
];

/// Overrides for auth flows that land on the end-user personal dashboard.
final userDashboardTestOverrides = [
  appAudienceProvider.overrideWith(
    () => _FixedAudienceNotifier(AppAudience.endUser),
  ),
  profileProvider.overrideWith((ref) async => dashboardTestProfile),
  personalDashboardProvider.overrideWith(
    () => FixedPersonalDashboardNotifier(dashboardTestPersonal()),
  ),
  metalPricesProvider.overrideWith(
    (ref) => Stream.value(dashboardTestMetalPrices()),
  ),
  unreadNotificationsCountProvider.overrideWithValue(
    const AsyncValue.data(0),
  ),
];
