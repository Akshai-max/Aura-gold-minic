import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ags_gold/services/service_providers.dart';
import 'package:ags_gold/features/splash/presentation/splash_screen.dart';
import 'package:ags_gold/features/auth/presentation/login_screen.dart';
import 'package:ags_gold/features/dashboard/presentation/dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  
  // Use a ValueNotifier to notify GoRouter when authentication status changes
  final listenable = ValueNotifier<AsyncValue<AuthStatus>>(authState);

  ref.listen<AsyncValue<AuthStatus>>(authNotifierProvider, (previous, next) {
    listenable.value = next;
  });

  ref.onDispose(() {
    listenable.dispose();
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: listenable,
    redirect: (context, state) {
      final authValue = ref.read(authNotifierProvider);
      final status = authValue.value ?? AuthStatus.initial;
      
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/';

      if (authValue.isLoading || status == AuthStatus.initial) {
        return isSplash ? null : '/';
      }

      if (status == AuthStatus.unauthenticated) {
        return isLoggingIn ? null : '/login';
      }

      if (status == AuthStatus.authenticated) {
        if (isLoggingIn || isSplash) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
});
