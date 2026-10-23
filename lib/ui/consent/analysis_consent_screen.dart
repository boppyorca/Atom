import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/consent/consent_view_model.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:provider/provider.dart';

class AnalysisConsentScreen extends StatelessWidget {
  const AnalysisConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final consent = context.watch<ConsentViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.analysisTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text(l10n.analysisWillRead),
          const SizedBox(height: AppSpacing.space2),
          Text('• ${l10n.analysisReadRepos}'),
          Text('• ${l10n.analysisReadLinks}'),
          Text('• ${l10n.analysisReadJob}'),
          const SizedBox(height: AppSpacing.space4),
          Text(l10n.analysisNever),
          const SizedBox(height: AppSpacing.space2),
          Text('• ${l10n.analysisNeverPrivate}'),
          const SizedBox(height: AppSpacing.space4),
          Text(l10n.analysisNoCompany),
          const SizedBox(height: AppSpacing.space2),
          Text(l10n.analysisRevokeHint),
          const SizedBox(height: AppSpacing.space5),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _choose(context, consent, false),
                  child: Text(l10n.analysisDecline),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: FilledButton(
                  onPressed: () => _choose(context, consent, true),
                  child: Text(l10n.analysisAgree),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _choose(
    BuildContext context,
    ConsentViewModel consent,
    bool granted,
  ) async {
    await consent.choose(granted);
    if (context.mounted) context.pop();
  }
}
