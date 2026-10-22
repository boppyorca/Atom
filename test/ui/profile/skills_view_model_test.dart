import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/domain/models/skill.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';
import 'package:harness_app/ui/profile/skills_view_model.dart';

import '../../fakes/fake_profile_repository.dart';

void main() {
  test(
    'adding a skill keeps it as self-claimed and blocks a duplicate',
    () async {
      final repo = FakeProfileRepository();
      final vm = SkillsViewModel(repo);

      await vm.load();
      expect(vm.skills, isEmpty);

      expect(await vm.add('Flutter'), isTrue);
      expect(vm.skills.single.name, 'Flutter');
      expect(vm.skills.single.confidence, SkillConfidence.selfClaimed);

      expect(await vm.add(' flutter '), isFalse);
      expect(vm.failure, isA<ValidationFailure>());
      expect(vm.skills, hasLength(1));
    },
  );

  test('deleting a skill removes it', () async {
    final repo = FakeProfileRepository();
    final vm = SkillsViewModel(repo);
    await vm.add('Dart');

    await vm.delete(vm.skills.single);
    expect(vm.skills, isEmpty);
    expect(repo.skills, isEmpty);
  });

  test('a failed load surfaces the error', () async {
    final repo = FakeProfileRepository()
      ..loadError = const Error(NetworkFailure());
    final vm = SkillsViewModel(repo);

    await vm.load();
    expect(vm.failure, isA<NetworkFailure>());
    expect(vm.loading, isFalse);
  });
}
