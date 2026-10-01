import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/loading_indicator.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/dashboard/presentation/admin_dashboard_screen.dart';
import '../features/dashboard/presentation/intern_dashboard_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String loading = '/loading';
  static const String login = '/login';
  static const String admin = '/admin';
  static const String intern = '/intern';
}

/// Decides where the user belongs, given the session and the current path.
/// Returns null when the current path is already right.
String? resolveRedirect(AsyncValue<dynamic> session, String location) {
  if (session.isLoading) {
    // Stay on the login screen while a sign-in is being checked, so its
    // error message is not lost. Everywhere else show a loader.
    if (location == AppRoutes.login || location == AppRoutes.loading) {
      return null;
    }
    return AppRoutes.loading;
  }

  final user = session.value;
  if (user == null) {
    return location == AppRoutes.login ? null : AppRoutes.login;
  }

  final home = user.isAdmin ? AppRoutes.admin : AppRoutes.intern;
  return location == home || location.startsWith('$home/') ? null : home;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.loading,
    refreshListenable: refresh,
    redirect: (context, state) =>
        resolveRedirect(ref.read(sessionProvider), state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.loading,
        builder: (_, _) => const Scaffold(body: LoadingIndicator()),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.admin,
        builder: (_, _) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.intern,
        builder: (_, _) => const InternDashboardScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
