import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harness_app/data/repositories/auth_repository.dart';
import 'package:harness_app/routing/routes.dart';
import 'package:harness_app/ui/auth/otp_screen.dart';
import 'package:harness_app/ui/auth/otp_view_model.dart';
import 'package:harness_app/ui/auth/sign_in_screen.dart';
import 'package:harness_app/ui/auth/sign_in_view_model.dart';
import 'package:harness_app/ui/discover/discover_screen.dart';
import 'package:harness_app/ui/profile/profile_screen.dart';
import 'package:harness_app/ui/salary/salary_screen.dart';
import 'package:harness_app/ui/settings/settings_screen.dart';
import 'package:harness_app/ui/settings/settings_view_model.dart';
import 'package:harness_app/ui/shell/app_shell.dart';
import 'package:provider/provider.dart';

GoRouter createRouter(AuthRepository authRepository) {
  return GoRouter(
    initialLocation: Routes.profile,
    refreshListenable: authRepository,
    redirect: (BuildContext context, GoRouterState state) {
      final signedIn = authRepository.isSignedIn;
      final onAuth = state.matchedLocation.startsWith(Routes.signIn);
      if (!signedIn && !onAuth) return Routes.signIn;
      if (signedIn && onAuth) return Routes.profile;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => SignInViewModel(authRepository),
          child: const SignInScreen(),
        ),
        routes: [
          GoRoute(
            path: 'otp',
            builder: (context, state) {
              final email = state.uri.queryParameters['email'] ?? '';
              return ChangeNotifierProvider(
                create: (_) => OtpViewModel(authRepository, email: email),
                child: const OtpScreen(),
              );
            },
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.discover,
                builder: (context, state) => const DiscoverScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.salary,
                builder: (context, state) => const SalaryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => ChangeNotifierProvider(
                  create: (_) => SettingsViewModel(authRepository),
                  child: const SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
