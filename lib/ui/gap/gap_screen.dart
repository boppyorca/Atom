import 'package:flutter/material.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:harness_app/ui/core/widgets/error_view.dart';
import 'package:harness_app/ui/gap/gap_view_model.dart';
import 'package:provider/provider.dart';

class GapScreen extends StatelessWidget {
  const GapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<GapViewModel>();
    final locale = Localizations.localeOf(context).languageCode;
    if (vm.loading && vm.snapshot == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.gapTitle)),
        body: Center(child: Text(l10n.loading)),
      );
    }
    if (vm.failure is NetworkFailure && vm.snapshot == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.gapTitle)),
        body: ErrorView(failure: vm.failure!, onRetry: vm.load),
      );
    }
    final remaining = vm.limit - vm.used;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.gapTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          TextField(
            decoration: InputDecoration(labelText: l10n.gapHint),
            minLines: 4,
            maxLines: 8,
            onChanged: (value) => vm.description = value,
          ),
          const SizedBox(height: AppSpacing.space4),
          FilledButton(
            onPressed: vm.running ? null : vm.start,
            child: Text(l10n.gapStart(remaining < 0 ? 0 : remaining, vm.limit)),
          ),
          const SizedBox(height: AppSpacing.space4),
          if (vm.running ||
              vm.snapshot?.status == 'queued' ||
              vm.snapshot?.status == 'running')
            Text(l10n.gapRunning),
          if (vm.failure is ValidationFailure &&
              (vm.failure! as ValidationFailure).code == 'quota_exceeded')
            Text(l10n.gapQuota),
          if (vm.failure is ValidationFailure &&
              (vm.failure! as ValidationFailure).code == 'no_skills')
            Text(l10n.gapEmptySkills),
          if (vm.failure is ValidationFailure &&
              (vm.failure! as ValidationFailure).code == 'input_invalid')
            Text(l10n.gapInvalid),
          if (vm.snapshot?.status == 'failed' ||
              vm.snapshot?.status == 'timed_out') ...[
            Text(l10n.gapFailed),
            const SizedBox(height: AppSpacing.space2),
            OutlinedButton(onPressed: vm.start, child: Text(l10n.retry)),
          ],
          if (vm.snapshot?.status == 'no_known_skills') Text(l10n.gapNoKnown),
          if (vm.snapshot?.status == 'ok') ...[
            Text(l10n.gapHave),
            for (final item in vm.snapshot!.have) Text(item.skill),
            Text(l10n.gapMissing),
            for (final item in vm.snapshot!.missing)
              Text(
                '${item.skill} — ${locale == 'vi' ? item.suggestionVi ?? '' : item.suggestionEn ?? ''}',
              ),
          ],
        ],
      ),
    );
  }
}
