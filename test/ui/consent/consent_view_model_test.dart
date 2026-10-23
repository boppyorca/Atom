import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/routing/routes.dart';
import 'package:harness_app/ui/consent/consent_view_model.dart';
import 'package:harness_app/ui/profile/skills_view_model.dart';

import '../../fakes/fake_profile_repository.dart';

void main() {
  test(
    'refusing sends analysis to the consent screen and skills still save',
    () async {
      final repo = FakeProfileRepository();
      final consent = ConsentViewModel(repo);
      await consent.load();

      await consent.choose(false);

      expect(consent.granted, isFalse);
      expect(consent.analysisDestination, Routes.aiConsent);

      final skills = SkillsViewModel(repo);
      expect(await skills.add('Flutter'), isTrue);
      expect(skills.skills, hasLength(1));
    },
  );

  test('withdrawing consent in settings takes effect immediately', () async {
    final repo = FakeProfileRepository()..storedConsent = true;
    final consent = ConsentViewModel(repo);
    await consent.load();
    expect(consent.granted, isTrue);

    await consent.choose(false);

    expect(consent.granted, isFalse);
    expect(consent.analysisDestination, Routes.aiConsent);
    expect(repo.storedConsent, isFalse);
  });

  test('a slow load does not undo a choice just made', () async {
    final repo = FakeProfileRepository();
    final gate = Completer<void>();
    repo.consentGate = gate;
    final consent = ConsentViewModel(repo);
    final pending = consent.load();

    await consent.choose(true);
    gate.complete();
    await pending;

    expect(consent.granted, isTrue);
    expect(repo.storedConsent, isTrue);
  });
}
