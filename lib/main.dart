import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harness_app/config/env.dart';
import 'package:harness_app/data/repositories/auth_repository.dart';
import 'package:harness_app/data/services/secure_session_storage.dart';
import 'package:harness_app/data/services/supabase_service.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/routing/router.dart';
import 'package:harness_app/ui/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
    authOptions: FlutterAuthClientOptions(localStorage: SecureSessionStorage()),
  );
  final authRepository = SupabaseAuthRepository(
    SupabaseService(Supabase.instance.client),
  );
  runApp(AtomApp(authRepository: authRepository));
}

class AtomApp extends StatefulWidget {
  const AtomApp({
    super.key,
    required this.authRepository,
    this.locale,
    this.router,
  });

  final AuthRepository authRepository;
  final Locale? locale;
  final GoRouter? router;

  @override
  State<AtomApp> createState() => _AtomAppState();
}

class _AtomAppState extends State<AtomApp> {
  late final GoRouter _router =
      widget.router ?? createRouter(widget.authRepository);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthRepository>.value(
      value: widget.authRepository,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: widget.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router,
      ),
    );
  }
}
