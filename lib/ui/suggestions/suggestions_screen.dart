import 'package:flutter/material.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:harness_app/ui/core/widgets/busy_button.dart';
import 'package:harness_app/ui/core/widgets/error_view.dart';
import 'package:harness_app/ui/suggestions/suggestions_view_model.dart';
import 'package:provider/provider.dart';

class SuggestionsScreen extends StatelessWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<SuggestionsViewModel>();
    if (vm.loading && vm.suggestions.isEmpty && vm.jobStatus == null) {
      return Scaffold(body: Center(child: Text(l10n.loading)));
    }
    if (vm.failure != null && vm.suggestions.isEmpty && vm.jobStatus == null) {
      return Scaffold(
        body: ErrorView(failure: vm.failure!, onRetry: vm.load),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.suggestionsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          if (vm.unseen) Text(l10n.suggestionsReady),
          if (vm.jobStatus == 'queued' || vm.jobStatus == 'running')
            Text(l10n.suggestionsRunning),
          if (vm.jobStatus == 'timed_out') Text(l10n.suggestionsTimedOut),
          if (vm.suggestions.isEmpty && vm.jobStatus == 'succeeded')
            Text(l10n.suggestionsNone),
          for (final suggestion in vm.suggestions) ...[
            Text(
              suggestion.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (suggestion.sources.isNotEmpty)
              Text(suggestion.sources.join(', ')),
            if (suggestion.because.isNotEmpty)
              Text('${l10n.suggestionBecause} ${suggestion.because}'),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => vm.reject(suggestion),
                    child: Text(l10n.suggestionReject),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: FilledButton(
                    onPressed: () => vm.accept(suggestion),
                    child: Text(l10n.suggestionAccept),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.space4),
          Text(l10n.suggestionsRemaining(vm.limit - vm.used, vm.limit)),
          const SizedBox(height: AppSpacing.space2),
          BusyButton(
            label: l10n.suggestionsStart,
            busy: vm.running,
            onPressed: vm.used >= vm.limit ? null : vm.start,
          ),
        ],
      ),
    );
  }
}
