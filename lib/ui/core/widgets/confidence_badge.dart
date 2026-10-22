import 'package:flutter/material.dart';
import 'package:harness_app/domain/models/skill.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';

class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({super.key, required this.confidence});

  final SkillConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, label) = switch (confidence) {
      SkillConfidence.selfClaimed => (
        Icons.person_outline,
        l10n.confidenceSelfClaimed,
      ),
      SkillConfidence.evidenced => (Icons.link, l10n.confidenceEvidenced),
      SkillConfidence.endorsed => (
        Icons.verified_outlined,
        l10n.confidenceEndorsed,
      ),
    };
    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(icon, size: AppSpacing.space4)),
          const SizedBox(width: AppSpacing.space1),
          Text(label),
        ],
      ),
    );
  }
}
