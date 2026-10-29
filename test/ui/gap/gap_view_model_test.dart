import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/domain/analysis/gap.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';
import 'package:harness_app/ui/gap/gap_view_model.dart';

import '../../fakes/fake_profile_repository.dart';

void main() {
  test('an empty job text is refused before any analysis starts', () async {
    final repo = FakeProfileRepository();
    final vm = GapViewModel(repo);
    expect(await vm.start(), isFalse);
    expect(repo.gapStarts, 0);
    expect((vm.failure! as ValidationFailure).code, 'input_invalid');
  });

  test(
    'a finished comparison shows skills the person has and skills they lack',
    () async {
      final repo = FakeProfileRepository()
        ..gapSnapshot = const GapSnapshot(
          status: 'ok',
          have: [GapItem(skill: 'Flutter', confidence: 'evidenced')],
          missing: [
            GapItem(skill: 'CI/CD', suggestionVi: 'Thêm một bước CI/CD.'),
          ],
        );
      final vm = GapViewModel(repo);
      await vm.load();
      expect(vm.snapshot?.have.single.skill, 'Flutter');
      expect(vm.snapshot?.missing.single.skill, 'CI/CD');
    },
  );

  test('no recognized skill and a used-up quota are both visible', () async {
    final repo = FakeProfileRepository()
      ..gapSnapshot = const GapSnapshot(status: 'no_known_skills')
      ..gapResult = const Error(ValidationFailure('quota_exceeded'));
    final vm = GapViewModel(repo);
    await vm.load();
    expect(vm.snapshot?.status, 'no_known_skills');
    vm.description = 'Flutter developer';
    expect(await vm.start(), isFalse);
    expect((vm.failure! as ValidationFailure).code, 'quota_exceeded');
  });

  test('a failed run can be retried', () async {
    final repo = FakeProfileRepository()
      ..gapSnapshot = const GapSnapshot(status: 'failed');
    final vm = GapViewModel(repo)..description = 'Cần Flutter';
    await vm.load();
    expect(vm.snapshot?.status, 'failed');
    expect(await vm.start(), isTrue);
    expect(repo.gapStarts, 1);
  });
}
