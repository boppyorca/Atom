import 'package:flutter/material.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';

class FindSkillsScreen extends StatelessWidget {
  const FindSkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.findSkills)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Text(l10n.chooseReposFirst),
      ),
    );
  }
}
