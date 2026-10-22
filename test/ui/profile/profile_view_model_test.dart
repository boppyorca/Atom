import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';
import 'package:harness_app/ui/profile/profile_view_model.dart';

import '../../fakes/fake_profile_repository.dart';

void main() {
  test('loads the profile and its city', () async {
    final repo = FakeProfileRepository()
      ..profile = const Profile(id: 'me', displayName: 'Minh', cityId: 2);
    final vm = ProfileViewModel(repo);

    await vm.load();

    expect(vm.loading, isFalse);
    expect(vm.profile?.displayName, 'Minh');
    expect(vm.city?.code, 'hcm');
  });

  test('offline load shows the failure, retry recovers', () async {
    final repo = FakeProfileRepository()
      ..loadError = const Error(NetworkFailure());
    final vm = ProfileViewModel(repo);

    await vm.load();
    expect(vm.failure, isA<NetworkFailure>());
    expect(vm.profile, isNull);

    repo.loadError = null;
    await vm.load();
    expect(vm.failure, isNull);
    expect(vm.profile?.displayName, 'Minh');
  });
}
