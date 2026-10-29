import 'package:flutter/material.dart';
import 'package:harness_app/domain/models/evidence.dart';
import 'package:harness_app/domain/models/skill.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:harness_app/ui/core/widgets/busy_button.dart';
import 'package:harness_app/ui/core/widgets/error_view.dart';
import 'package:harness_app/ui/evidence/evidence_view_model.dart';
import 'package:provider/provider.dart';

class EvidenceScreen extends StatefulWidget {
  const EvidenceScreen({super.key});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  final _url = TextEditingController();
  final _title = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<EvidenceViewModel>();
    if (vm.loading && vm.links.isEmpty && vm.failure == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.evidenceTitle)),
        body: Center(child: Text(l10n.loading)),
      );
    }
    if (vm.failure != null &&
        vm.links.isEmpty &&
        vm.failure is NetworkFailure) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.evidenceTitle)),
        body: ErrorView(failure: vm.failure!, onRetry: vm.load),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.evidenceTitle} ${vm.links.length}/10'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          if (vm.links.isEmpty) Text(l10n.evidenceEmpty),
          for (final link in vm.links)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(link.title ?? link.url),
              subtitle: Text(
                link.kind == EvidenceKind.article
                    ? l10n.evidenceArticle
                    : l10n.evidenceProduct,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (vm.skills.isNotEmpty)
                    PopupMenuButton<Skill>(
                      tooltip: l10n.attachEvidence,
                      onSelected: (skill) => vm.attach(skill, link),
                      itemBuilder: (context) => [
                        for (final skill in vm.skills)
                          PopupMenuItem(value: skill, child: Text(skill.name)),
                      ],
                      icon: const Icon(Icons.link),
                    ),
                  IconButton(
                    tooltip: l10n.deleteEvidence,
                    onPressed: () => vm.remove(link),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.space4),
          SegmentedButton<EvidenceKind>(
            segments: [
              ButtonSegment(
                value: EvidenceKind.article,
                label: Text(l10n.evidenceArticle),
              ),
              ButtonSegment(
                value: EvidenceKind.product,
                label: Text(l10n.evidenceProduct),
              ),
            ],
            selected: {vm.kind},
            onSelectionChanged: (value) => vm.kind = value.first,
          ),
          const SizedBox(height: AppSpacing.space4),
          TextField(
            controller: _url,
            decoration: InputDecoration(
              labelText: l10n.evidenceUrlLabel,
              errorText: _error(l10n, vm.failure),
            ),
            onChanged: (value) => vm.url = value,
          ),
          const SizedBox(height: AppSpacing.space2),
          TextField(
            controller: _title,
            decoration: InputDecoration(labelText: l10n.evidenceTitleLabel),
            onChanged: (value) => vm.title = value,
          ),
          const SizedBox(height: AppSpacing.space4),
          BusyButton(
            label: l10n.addEvidence,
            onPressed: () async {
              final added = await vm.add();
              if (added) {
                _url.clear();
                _title.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}

String? _error(AppLocalizations l10n, AppFailure? failure) {
  if (failure is ValidationFailure && failure.code == 'invalid_url') {
    return l10n.evidenceUrlInvalid;
  }
  if (failure is ValidationFailure && failure.code == 'evidence_limit') {
    return l10n.evidenceLimit;
  }
  if (failure is NetworkFailure) return l10n.noConnection;
  if (failure != null) return l10n.genericError;
  return null;
}
