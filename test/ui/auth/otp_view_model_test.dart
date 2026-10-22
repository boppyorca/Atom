import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/ui/auth/otp_view_model.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  test('wrong or expired code surfaces validation failure', () async {
    final auth = FakeAuthRepository()
      ..verifyResult = const Error(ValidationFailure('otp_invalid'));
    final vm = OtpViewModel(auth, email: 'minh@example.com')..token = '000000';

    expect(await vm.confirm(), isFalse);
    expect(vm.failure, isA<ValidationFailure>());
    expect(auth.signedIn, isFalse);
    expect(vm.running, isFalse);
  });

  test('valid code signs the user in', () async {
    final auth = FakeAuthRepository();
    final vm = OtpViewModel(auth, email: 'minh@example.com')..token = '123456';

    expect(await vm.confirm(), isTrue);
    expect(auth.lastToken, '123456');
    expect(auth.signedIn, isTrue);
  });
}
