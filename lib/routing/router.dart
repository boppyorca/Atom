import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harness_app/data/repositories/auth_repository.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/routing/routes.dart';
import 'package:harness_app/ui/auth/otp_screen.dart';
import 'package:harness_app/ui/auth/otp_view_model.dart';
import 'package:harness_app/ui/auth/sign_in_screen.dart';
import 'package:harness_app/ui/auth/sign_in_view_model.dart';
import 'package:harness_app/ui/chat/chat_screen.dart';
import 'package:harness_app/ui/chat/chat_view_model.dart';
import 'package:harness_app/ui/consent/analysis_consent_screen.dart';
import 'package:harness_app/ui/discover/discover_screen.dart';
import 'package:harness_app/ui/evidence/evidence_screen.dart';
import 'package:harness_app/ui/evidence/evidence_view_model.dart';
import 'package:harness_app/ui/github/github_repos_screen.dart';
import 'package:harness_app/ui/github/github_repos_view_model.dart';
import 'package:harness_app/ui/suggestions/suggestions_screen.dart';
import 'package:harness_app/ui/suggestions/suggestions_view_model.dart';
import 'package:harness_app/ui/profile/profile_edit_screen.dart';
import 'package:harness_app/ui/profile/profile_edit_view_model.dart';
import 'package:harness_app/ui/profile/profile_screen.dart';
import 'package:harness_app/ui/profile/profile_view_model.dart';
import 'package:harness_app/ui/profile/skills_screen.dart';
import 'package:harness_app/ui/profile/skills_view_model.dart';
import 'package:harness_app/ui/salary/salary_entry_screen.dart';
import 'package:harness_app/ui/salary/salary_entry_view_model.dart';
import 'package:harness_app/ui/salary/salary_screen.dart';
import 'package:harness_app/ui/salary/salary_view_model.dart';
import 'package:harness_app/ui/feed/feed_screen.dart';
import 'package:harness_app/ui/feed/feed_view_model.dart';
import 'package:harness_app/ui/gap/gap_screen.dart';
import 'package:harness_app/ui/gap/gap_view_model.dart';
import 'package:harness_app/ui/notices/notices_screen.dart';
import 'package:harness_app/ui/notices/notices_view_model.dart';
import 'package:harness_app/ui/safety/safety_screens.dart';
import 'package:harness_app/ui/safety/safety_view_model.dart';
import 'package:harness_app/ui/settings/delete_account_screen.dart';
import 'package:harness_app/ui/settings/settings_screen.dart';
import 'package:harness_app/ui/settings/settings_view_model.dart';
import 'package:harness_app/ui/shell/app_shell.dart';
import 'package:provider/provider.dart';

GoRouter createRouter(
  AuthRepository authRepository,
  ProfileRepository profileRepository,
) {
  return GoRouter(
    initialLocation: Routes.profile,
    refreshListenable: authRepository,
    redirect: (BuildContext context, GoRouterState state) {
      if (_isGithubLoginCallback(state.uri)) {
        return authRepository.isSignedIn ? Routes.githubRepos : Routes.signIn;
      }
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
                builder: (context, state) => ChangeNotifierProvider(
                  create: (_) => ProfileViewModel(profileRepository)..load(),
                  child: const ProfileScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => ChangeNotifierProvider(
                      create: (_) =>
                          ProfileEditViewModel(profileRepository)..load(),
                      child: const ProfileEditScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'skills',
                    builder: (context, state) => ChangeNotifierProvider(
                      create: (_) => SkillsViewModel(profileRepository)..load(),
                      child: const SkillsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'github',
                    builder: (context, state) => ChangeNotifierProvider(
                      create: (_) =>
                          GithubReposViewModel(profileRepository)..load(),
                      child: const GithubReposScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'suggestions',
                    builder: (context, state) => ChangeNotifierProvider(
                      create: (_) =>
                          SuggestionsViewModel(profileRepository)..load(),
                      child: const SuggestionsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'evidence',
                    builder: (context, state) => ChangeNotifierProvider(
                      create: (_) =>
                          EvidenceViewModel(profileRepository)..load(),
                      child: const EvidenceScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'gap',
                    builder: (context, state) => ChangeNotifierProvider(
                      create: (_) => GapViewModel(profileRepository)..load(),
                      child: const GapScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'chat',
                    builder: (context, state) => ChangeNotifierProvider(
                      create: (_) => ChatViewModel(profileRepository)..load(),
                      child: const ChatScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'feed',
                    builder: (context, state) => ChangeNotifierProvider(
                      create: (_) => FeedViewModel(profileRepository)..load(),
                      child: const FeedScreen(),
                    ),
                  ),
                ],
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
                builder: (context, state) => ChangeNotifierProvider(
                  create: (_) => SalaryViewModel(profileRepository)..load(),
                  child: const SalaryScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'entry',
                    builder: (context, state) => ChangeNotifierProvider(
                      create: (_) =>
                          SalaryEntryViewModel(profileRepository)..load(),
                      child: const SalaryEntryScreen(),
                    ),
                  ),
                ],
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
                routes: [
                  GoRoute(
                    path: 'delete',
                    builder: (context, state) => ChangeNotifierProvider(
                      create: (_) => SettingsViewModel(authRepository),
                      child: const DeleteAccountScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'blocked',
                    builder: (context, state) => ChangeNotifierProvider(
                      create: (_) => SafetyViewModel(profileRepository)..load(),
                      child: const BlockedPeopleScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'notices',
                    builder: (context, state) => ChangeNotifierProvider(
                      create: (_) =>
                          NoticesViewModel(profileRepository)..load(),
                      child: const NoticesScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'report',
                    builder: (context, state) => ChangeNotifierProvider(
                      create: (_) => SafetyViewModel(profileRepository),
                      child: const ReportProfileScreen(profileId: 'other'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.aiConsent,
        builder: (context, state) => const AnalysisConsentScreen(),
      ),
    ],
  );
}

bool _isGithubLoginCallback(Uri uri) {
  return uri.scheme == 'com.example.harnessapp' || uri.host == 'login-callback';
}
