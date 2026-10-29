import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/domain/models/blocked_person.dart';
import 'package:harness_app/ui/safety/safety_view_model.dart';

import '../../fakes/fake_profile_repository.dart';

void main() {
  test('report, block and unblock wait for confirmation and then say what happened', () async {
    final repo = FakeProfileRepository();
    final vm = SafetyViewModel(repo);

    expect(
      await vm.report(profileId: 'lan', reason: 'spam', confirmed: false),
      isFalse,
    );
    expect(repo.reportCount, 0);

    expect(
      await vm.report(profileId: 'lan', reason: 'spam', confirmed: true),
      isTrue,
    );
    expect(vm.notice, 'reported');

    expect(await vm.block('lan', confirmed: false), isFalse);
    expect(repo.blockCount, 0);
    expect(await vm.block('lan', confirmed: true), isTrue);
    expect(vm.notice, 'blocked');

    vm.blocked = [const BlockedPerson(id: 'lan', name: 'Lan')];
    expect(await vm.unblock('lan', confirmed: true), isTrue);
    expect(vm.blocked, isEmpty);
    expect(vm.notice, 'unblocked');
  });
}
