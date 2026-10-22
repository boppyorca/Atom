import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/salary/salary_entry_view_model.dart';
import 'package:harness_app/ui/salary/salary_view_model.dart';

import '../../fakes/fake_profile_repository.dart';

void main() {
  test('fewer than five entries shows not enough data', () async {
    final vm = SalaryViewModel(FakeProfileRepository());
    await vm.load();
    vm
      ..roleId = 1
      ..cityId = 2
      ..seniority = SeniorityLevel.fresher;

    await vm.lookup();

    expect(vm.aggregate?.insufficient, isTrue);
    expect(vm.failure, isNull);
  });

  test('a salary entry needs all four fields', () async {
    final vm = SalaryEntryViewModel(FakeProfileRepository());

    expect(await vm.save(), isFalse);
    expect(vm.failure, isA<ValidationFailure>());
  });
}
