import 'package:flutter/material.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:harness_app/ui/core/widgets/busy_button.dart';
import 'package:harness_app/ui/core/widgets/confidence_badge.dart';
import 'package:harness_app/ui/core/widgets/error_view.dart';
import 'package:harness_app/ui/profile/skills_view_model.dart';
import 'package:provider/provider.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<SkillsViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.skillsTitle)),
      body: switch ((vm.loading, vm.failure, vm.skills.isEmpty)) {
        (true, _, true) => Center(child: Text(l10n.loading)),
        (_, final failure?, true) => ErrorView(
          failure: failure,
          onRetry: vm.load,
        ),
        _ => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            if (vm.skills.isEmpty)
              Text(l10n.skillsEmpty)
            else
              for (final skill in vm.skills)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(skill.name),
                  subtitle: ConfidenceBadge(confidence: skill.confidence),
                  trailing: IconButton(
                    tooltip: l10n.deleteSkill,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: vm.saving ? null : () => vm.delete(skill),
                  ),
                ),
            const SizedBox(height: AppSpacing.space4),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: l10n.skillNameLabel,
                errorText: _fieldError(l10n, vm.failure),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            BusyButton(
              label: l10n.addSkill,
              busy: vm.saving,
              onPressed: () async {
                final added = await vm.add(_name.text);
                if (added) _name.clear();
              },
            ),
          ],
        ),
      },
    );
  }
}

String? _fieldError(AppLocalizations l10n, AppFailure? failure) {
  if (failure is ValidationFailure && failure.code == 'duplicate_skill') {
    return l10n.skillDuplicate;
  }
  if (failure is NetworkFailure) return l10n.noConnection;
  if (failure != null) return l10n.genericError;
  return null;
}
