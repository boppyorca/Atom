import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/ui/auth/sign_in_view_model.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  test('invalid email sets field error and does not call repository', () async {
    final auth = FakeAuthRepository();
    final vm = SignInViewModel(auth)..email = 'not-an-email';

    expect(await vm.submit(), isFalse);
    expect(vm.emailFormatError, isTrue);
    expect(auth.requestCount, 0);
    expect(vm.running, isFalse);
  });

  test('valid email requests a code', () async {
    final auth = FakeAuthRepository();
    final vm = SignInViewModel(auth)..email = 'minh@example.com';

    expect(await vm.submit(), isTrue);
    expect(auth.lastEmail, 'minh@example.com');
    expect(vm.running, isFalse);
  });

  test('network failure is visible and UI is not left running', () async {
    final auth = FakeAuthRepository()
      ..requestResult = const Error(NetworkFailure());
    final vm = SignInViewModel(auth)..email = 'minh@example.com';

    expect(await vm.submit(), isFalse);
    expect(vm.failure, isA<NetworkFailure>());
    expect(vm.running, isFalse);
  });
}
