import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/domain/models/skill.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/core/widgets/confidence_badge.dart';

void main() {
  testWidgets('each confidence level shows words and an icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              ConfidenceBadge(confidence: SkillConfidence.selfClaimed),
              ConfidenceBadge(confidence: SkillConfidence.evidenced),
              ConfidenceBadge(confidence: SkillConfidence.endorsed),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Tự khai'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('Có bằng chứng'), findsOneWidget);
    expect(find.byIcon(Icons.link), findsOneWidget);
    expect(find.text('Được xác nhận'), findsOneWidget);
    expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
  });
}
