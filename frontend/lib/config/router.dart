import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/insights/insights_screen.dart';
import '../screens/trades/trade_form_screen.dart';
import '../screens/trades/trade_detail_screen.dart';
import '../screens/trades/trades_list_screen.dart';
import '../widgets/app_shell.dart';
import '../widgets/loading_view.dart';

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final loggingInOrUp = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (auth.status == AuthStatus.unknown) return null;

      if (!loggedIn && !loggingInOrUp) return '/login';
      if (loggedIn && loggingInOrUp) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/trades/new',
        builder: (_, __) => const TradeFormScreen(),
      ),
      GoRoute(
        path: '/trades/:id/edit',
        builder: (_, state) => TradeFormScreen(tradeId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/trades/:id',
        builder: (_, state) => TradeDetailScreen(tradeId: state.pathParameters['id']!),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (_, __) => const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/trades',
            pageBuilder: (_, __) => const NoTransitionPage(child: TradesListScreen()),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (_, __) => const NoTransitionPage(child: AnalyticsScreen()),
          ),
          GoRoute(
            path: '/insights',
            pageBuilder: (_, __) => const NoTransitionPage(child: InsightsScreen()),
          ),
        ],
      ),
    ],
    errorBuilder: (_, __) => const LoadingView(message: 'Page not found'),
  );
}

/// Convenience: routes lay out together for the navigation bar/rail.
class ShellDestinations {
  static const items = [
    ShellDestination(path: '/dashboard', label: 'Dashboard', icon: 'dashboard'),
    ShellDestination(path: '/trades', label: 'Trades', icon: 'list'),
    ShellDestination(path: '/analytics', label: 'Analytics', icon: 'chart'),
    ShellDestination(path: '/insights', label: 'Insights', icon: 'insight'),
  ];
}

class ShellDestination {
  final String path;
  final String label;
  final String icon;
  const ShellDestination({required this.path, required this.label, required this.icon});
}

/// Helper to read auth from anywhere with less ceremony.
extension AuthContext on BuildContext {
  AuthProvider get auth => read<AuthProvider>();
  AuthProvider get watchAuth => watch<AuthProvider>();
}
