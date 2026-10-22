import 'package:flutter/material.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, required this.onRetry});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                failureMessage(l10n, failure),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

String failureMessage(AppLocalizations l10n, AppFailure failure) {
  return switch (failure) {
    NetworkFailure() => l10n.noConnection,
    _ => l10n.genericError,
  };
}
