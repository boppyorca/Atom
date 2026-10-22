import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';
import 'package:harness_app/ui/profile/profile_edit_view_model.dart';

import '../../fakes/fake_profile_repository.dart';

void main() {
  Future<ProfileEditViewModel> loaded(FakeProfileRepository repo) async {
    final vm = ProfileEditViewModel(repo);
    await vm.load();
    return vm;
  }

  test('saves name, bio, city and contact; reopening shows them', () async {
    final repo = FakeProfileRepository();
    final vm = await loaded(repo)
      ..displayName = ' Minh Nguyen '
      ..bio = 'Flutter dev'
      ..cityId = 2
      ..contactType = ContactLinkType.email
      ..contactValue = 'minh@example.com'
      ..contactVisible = true;

    expect(await vm.save(), isTrue);

    final reopened = await loaded(repo);
    expect(reopened.displayName, 'Minh Nguyen');
    expect(reopened.bio, 'Flutter dev');
    expect(reopened.cityId, 2);
    expect(reopened.contactType, ContactLinkType.email);
    expect(reopened.contactValue, 'minh@example.com');
    expect(reopened.contactVisible, isTrue);
    expect(reopened.cities.map((c) => c.code), ['hn', 'hcm']);
  });

  test('bio counts remaining characters and blocks saving over 300', () async {
    final repo = FakeProfileRepository();
    final vm = await loaded(repo)..bio = 'a' * 55;
    expect(vm.bioRemaining, 245);

    vm.bio = 'a' * 300;
    expect(vm.bioRemaining, 0);
    expect(vm.bioTooLong, isFalse);

    vm.bio = 'a' * 301;
    expect(vm.bioRemaining, -1);
    expect(vm.bioTooLong, isTrue);
    expect(await vm.save(), isFalse);
    expect(repo.saveCount, 0);
  });

  test('bio length counts characters like the database does', () async {
    final vm = await loaded(FakeProfileRepository())..bio = 'Việt 🙂';
    expect(vm.bioRemaining, 300 - 6);
  });

  test('empty name blocks saving', () async {
    final repo = FakeProfileRepository();
    final vm = await loaded(repo)..displayName = '   ';

    expect(await vm.save(), isFalse);
    expect(vm.nameError, isTrue);
    expect(repo.saveCount, 0);
  });

  test('contact in the wrong format blocks saving', () async {
    final repo = FakeProfileRepository();
    final vm = await loaded(repo)
      ..contactType = ContactLinkType.linkedin
      ..contactValue = 'https://example.com/me';

    expect(await vm.save(), isFalse);
    expect(vm.contactError, isTrue);
    expect(repo.saveCount, 0);
  });

  test('choosing no contact clears the stored contact', () async {
    final repo = FakeProfileRepository()
      ..profile = const Profile(
        id: 'me',
        displayName: 'Minh',
        contactType: ContactLinkType.email,
        contactValue: 'minh@example.com',
      );
    final vm = await loaded(repo)..contactType = null;

    expect(await vm.save(), isTrue);
    expect(repo.profile.contactType, isNull);
    expect(repo.profile.contactValue, isNull);
  });

  test('offline save keeps the typed data and shows the failure', () async {
    final repo = FakeProfileRepository()
      ..saveError = const Error(NetworkFailure());
    final vm = await loaded(repo)..bio = 'Typed while offline';

    expect(await vm.save(), isFalse);
    expect(vm.saveFailure, isA<NetworkFailure>());
    expect(vm.saving, isFalse);
    expect(vm.bio, 'Typed while offline');
  });

  test('offline load shows the failure and retry recovers', () async {
    final repo = FakeProfileRepository()
      ..loadError = const Error(NetworkFailure());
    final vm = await loaded(repo);
    expect(vm.loading, isFalse);
    expect(vm.loadFailure, isA<NetworkFailure>());

    repo.loadError = null;
    await vm.load();
    expect(vm.loadFailure, isNull);
    expect(vm.displayName, 'Minh');
  });
}
