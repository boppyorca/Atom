import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harness_app/config/env.dart';
import 'package:harness_app/data/repositories/auth_repository.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/data/services/locale_preference.dart';
import 'package:harness_app/data/services/secure_session_storage.dart';
import 'package:harness_app/data/services/supabase_service.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/routing/router.dart';
import 'package:harness_app/ui/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
    authOptions: FlutterAuthClientOptions(localStorage: SecureSessionStorage()),
  );
  final service = SupabaseService(Supabase.instance.client);
  final localePreference = LocalePreference(
    SharedPreferencesStore(await SharedPreferences.getInstance()),
    deviceLocale: WidgetsBinding.instance.platformDispatcher.locale,
  );
  await localePreference.load();
  runApp(
    AtomApp(
      authRepository: SupabaseAuthRepository(service),
      profileRepository: SupabaseProfileRepository(service),
      localePreference: localePreference,
    ),
  );
}

class AtomApp extends StatefulWidget {
  const AtomApp({
    super.key,
    required this.authRepository,
    required this.profileRepository,
    this.localePreference,
    this.locale,
    this.router,
  });

  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final LocalePreference? localePreference;
  final Locale? locale;
  final GoRouter? router;

  @override
  State<AtomApp> createState() => _AtomAppState();
}

class _AtomAppState extends State<AtomApp> {
  late final LocalePreference _localePreference =
      widget.localePreference ?? LocalePreference(MemoryPreferenceStore());
  late final GoRouter _router =
      widget.router ??
      createRouter(widget.authRepository, widget.profileRepository);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LocalePreference>.value(
      value: _localePreference,
      child: ChangeNotifierProvider<AuthRepository>.value(
        value: widget.authRepository,
        child: ListenableBuilder(
          listenable: _localePreference,
          builder: (context, _) => MaterialApp.router(
            theme: AppTheme.light(),
            locale: widget.locale ?? _localePreference.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
