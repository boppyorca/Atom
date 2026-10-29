import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';
import 'package:harness_app/ui/settings/settings_view_model.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  test('a failed delete stays signed in', () async {
    final auth = FakeAuthRepository()
      ..signedIn = true
      ..deleteResult = const Error(NetworkFailure());
    final vm = SettingsViewModel(auth);

    expect(await vm.deleteAccount(), isFalse);
    expect(auth.signedIn, isTrue);
    expect(auth.signOutCount, 0);
  });

  test('a successful delete signs out', () async {
    final auth = FakeAuthRepository()..signedIn = true;
    final vm = SettingsViewModel(auth);

    expect(await vm.deleteAccount(), isTrue);
    expect(auth.signedIn, isFalse);
    expect(auth.signOutCount, 1);
  });
}
