import 'package:flutter/material.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/analysis/job_compare_view_model.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:harness_app/ui/core/widgets/busy_button.dart';
import 'package:provider/provider.dart';

class JobCompareScreen extends StatelessWidget {
  const JobCompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<JobCompareViewModel>();
    final group = vm.group;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.compareJobTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          TextField(
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: l10n.jobTextLabel,
              errorText: vm.tooLong ? l10n.jobTooLong : null,
            ),
            onChanged: (value) => vm.job = value,
          ),
          const SizedBox(height: AppSpacing.space4),
          BusyButton(label: l10n.compareJob, onPressed: vm.compare),
          if (group != null && group.have.isEmpty && group.missing.isEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            Text(l10n.jobNoSkills),
          ],
          if (group != null && group.have.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            Text(l10n.jobHave),
            for (final name in group.have) Text(name),
          ],
          if (group != null && group.missing.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            Text(l10n.jobMissing),
            for (final name in group.missing)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(name),
                trailing: TextButton(
                  onPressed: () => vm.claim(name),
                  child: Text(l10n.claimSkill),
                ),
              ),
          ],
          if (vm.full) ...[
            const SizedBox(height: AppSpacing.space4),
            Text(l10n.skillListFull),
          ],
        ],
      ),
    );
  }
}
