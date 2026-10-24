import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/domain/models/skill.dart';
import 'package:harness_app/ui/analysis/job_compare_view_model.dart';

import '../../fakes/fake_profile_repository.dart';

void main() {
  test('claiming a missing skill marks it self-claimed', () async {
    final repo = FakeProfileRepository();
    final vm = JobCompareViewModel(repo);
    await vm.load();
    vm.job = 'Cần Flutter';

    vm.compare();
    expect(vm.group?.missing, ['Flutter']);

    expect(await vm.claim('Flutter'), isTrue);
    expect(repo.skills.single.confidence, SkillConfidence.selfClaimed);
    expect(vm.group?.have, ['Flutter']);
    expect(vm.group?.missing, isEmpty);
  });

  test('a full profile cannot claim another skill', () async {
    final repo = FakeProfileRepository();
    repo.skills = [
      for (var i = 0; i < 50; i++)
        Skill(
          id: '$i',
          name: 'Skill $i',
          confidence: SkillConfidence.selfClaimed,
        ),
    ];
    final vm = JobCompareViewModel(repo);
    await vm.load();

    expect(await vm.claim('Flutter'), isFalse);
    expect(vm.full, isTrue);
    expect(repo.skills, hasLength(50));
  });
}
