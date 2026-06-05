import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/permissions.dart';
import '../core/widgets/app_shell.dart';
import '../features/audit/presentation/audit_screen.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/password_screens.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/gold_price/presentation/admin_gold_settings_screen.dart';
import '../features/gold_price/presentation/gold_price_widgets.dart';
import '../features/gold_wallet/presentation/gold_wallet_screen.dart';
import '../features/portfolio/presentation/portfolio_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/roles/presentation/roles_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/transactions/presentation/transaction_history_screen.dart';
import '../features/users/presentation/users_screen.dart';
import '../features/buy_gold/presentation/buy_gold_screen.dart';
import '../features/buy_gold/presentation/buy_review_screen.dart';
import '../features/sell_gold/presentation/sell_gold_screen.dart';
import '../features/sell_gold/presentation/sell_review_screen.dart';
import '../features/orders/presentation/order_history_screen.dart';
import '../features/orders/domain/order.dart';
import '../features/payments/presentation/payment_status_screen.dart';
import '../features/transaction_details/presentation/transaction_details_screen.dart';
import '../features/settings/presentation/admin_trading_settings_screen.dart';
import '../features/treasury/presentation/admin_treasury_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final path = state.uri.path;
      final public =
          {'/login', '/register', '/forgot-password'}.contains(path) ||
              path.startsWith('/reset-password');
      if (!auth.isAuthenticated && !public) return '/login';
      if (auth.isAuthenticated && public) return '/dashboard';
      if (!_hasPermission(path, auth.permissions, auth.user?.role)) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password/:token',
        builder: (_, state) =>
            ResetPasswordScreen(token: state.pathParameters['token']!),
      ),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
            path: '/wallet',
            builder: (_, __) => const GoldWalletScreen(),
          ),
          GoRoute(
            path: '/portfolio',
            builder: (_, __) => const PortfolioScreen(),
          ),
          GoRoute(
            path: '/gold-price',
            builder: (_, __) => const GoldPriceDetailsScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (_, __) => const TransactionHistoryScreen(),
          ),
          GoRoute(path: '/users', builder: (_, __) => const UsersScreen()),
          GoRoute(path: '/roles', builder: (_, __) => const RolesScreen()),
          GoRoute(path: '/audit', builder: (_, __) => const AuditScreen()),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/gold-settings',
            builder: (_, __) => const AdminGoldSettingsScreen(),
          ),
          GoRoute(
            path: '/buy-gold',
            builder: (_, __) => const BuyGoldScreen(),
          ),
          GoRoute(
            path: '/buy-review',
            builder: (_, __) => const BuyReviewScreen(),
          ),
          GoRoute(
            path: '/sell-gold',
            builder: (_, __) => const SellGoldScreen(),
          ),
          GoRoute(
            path: '/sell-review',
            builder: (_, __) => const SellReviewScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (_, __) => const OrderHistoryScreen(),
          ),
          GoRoute(
            path: '/transaction-details/:id',
            builder: (_, state) => TransactionDetailsScreen(
              orderId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/payment-status',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>;
              return PaymentStatusScreen(
                order: extra['order'] as OrderModel,
                success: extra['success'] as bool,
              );
            },
          ),
          GoRoute(
            path: '/admin-trading-settings',
            builder: (_, __) => const AdminTradingSettingsScreen(),
          ),
          GoRoute(
            path: '/treasury',
            builder: (_, __) => const AdminTreasuryScreen(),
          ),
        ],
      ),
    ],
  );
});

bool _hasPermission(String path, List<String> permissions, String? role) {
  if (path.startsWith('/users')) {
    return permissions.contains(Permissions.userRead);
  }
  if (path.startsWith('/roles')) return role == AppRoles.admin;
  if (path.startsWith('/audit')) {
    return permissions.contains(Permissions.auditRead);
  }
  if (path.startsWith('/settings')) {
    return permissions.contains(Permissions.settingsManage);
  }
  if (path.startsWith('/gold-settings')) return role == AppRoles.admin;
  if (path.startsWith('/admin-trading-settings')) return role == AppRoles.admin;
  if (path.startsWith('/treasury')) return role == AppRoles.admin;
  return true;
}
