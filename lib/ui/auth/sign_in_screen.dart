import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/routing/routes.dart';
import 'package:harness_app/ui/auth/sign_in_view_model.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/theme/app_colors.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:harness_app/ui/core/widgets/busy_button.dart';
import 'package:provider/provider.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<SignInViewModel>();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const SizedBox(height: AppSpacing.space6),
            Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              l10n.appTagline,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.space6),
            TextField(
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: l10n.emailLabel,
                hintText: l10n.emailHint,
                errorText: vm.emailFormatError ? l10n.invalidEmail : null,
              ),
              onChanged: (value) => vm.email = value,
            ),
            if (vm.failure != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Semantics(
                liveRegion: true,
                child: Text(
                  _message(l10n, vm.failure!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space4),
            BusyButton(
              label: l10n.sendLoginCode,
              busy: vm.running,
              onPressed: () async {
                final ok = await vm.submit();
                if (ok && context.mounted) {
                  context.go(Routes.signInOtpWithEmail(vm.email.trim()));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _message(AppLocalizations l10n, AppFailure failure) {
    return switch (failure) {
      NetworkFailure() => l10n.noConnection,
      _ => l10n.genericError,
    };
  }
}
