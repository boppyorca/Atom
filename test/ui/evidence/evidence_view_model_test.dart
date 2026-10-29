import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/domain/models/skill.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/evidence/evidence_view_model.dart';

import '../../fakes/fake_profile_repository.dart';

void main() {
  test('a bad url is blocked before it is saved', () async {
    final vm = EvidenceViewModel(FakeProfileRepository());
    vm
      ..url = 'not-a-url'
      ..title = 'Notes';

    expect(await vm.add(), isFalse);
    expect(vm.failure, isA<ValidationFailure>());
    expect(vm.links, isEmpty);
  });

  test('the eleventh link is refused', () async {
    final repo = FakeProfileRepository();
    final vm = EvidenceViewModel(repo);
    for (var i = 0; i < 10; i++) {
      vm
        ..url = 'https://example.com/$i'
        ..title = 'Item $i';
      expect(await vm.add(), isTrue);
    }
    vm
      ..url = 'https://example.com/11'
      ..title = 'Too many';

    expect(await vm.add(), isFalse);
    expect((vm.failure! as ValidationFailure).code, 'evidence_limit');
  });

  test('attaching a link marks a self-claimed skill as evidenced', () async {
    final repo = FakeProfileRepository()
      ..skills = [
        const Skill(
          id: 'skill-1',
          name: 'Flutter',
          confidence: SkillConfidence.selfClaimed,
        ),
      ];
    final vm = EvidenceViewModel(repo);
    await vm.load();
    vm
      ..url = 'https://example.com/flutter'
      ..title = 'Notes';
    expect(await vm.add(), isTrue);

    expect(await vm.attach(vm.skills.single, vm.links.single), isTrue);
    expect(vm.skills.single.confidence, SkillConfidence.evidenced);
  });
}
