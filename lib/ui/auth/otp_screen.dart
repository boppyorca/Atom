import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/routing/routes.dart';
import 'package:harness_app/ui/auth/otp_view_model.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:harness_app/ui/core/widgets/busy_button.dart';
import 'package:provider/provider.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<OtpViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.enterCodeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text(l10n.codeSentTo(vm.email)),
          const SizedBox(height: AppSpacing.space4),
          TextField(
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.otpHint,
              errorText: vm.failure is ValidationFailure
                  ? l10n.otpInvalid
                  : null,
            ),
            onChanged: (value) => vm.token = value,
          ),
          if (vm.failure is NetworkFailure || vm.failure is ServerFailure) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                vm.failure is NetworkFailure
                    ? l10n.noConnection
                    : l10n.genericError,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
          const SizedBox(height: AppSpacing.space4),
          BusyButton(
            label: l10n.confirm,
            busy: vm.running,
            onPressed: () async {
              final ok = await vm.confirm();
              if (ok && context.mounted) context.go(Routes.profile);
            },
          ),
          const SizedBox(height: AppSpacing.space2),
          TextButton(
            onPressed: vm.running ? null : vm.resend,
            child: Text(l10n.resendCode),
          ),
        ],
      ),
    );
  }
}
