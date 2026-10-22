import 'dart:async';

import 'package:fake_async/fake_async.dart';
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
    vm.dispose();
  });

  test('valid code signs the user in', () async {
    final auth = FakeAuthRepository();
    final vm = OtpViewModel(auth, email: 'minh@example.com')..token = '123456';

    expect(await vm.confirm(), isTrue);
    expect(auth.lastToken, '123456');
    expect(auth.signedIn, isTrue);
    vm.dispose();
  });

  test('entering the code screen locks resend and counts down from 60', () {
    fakeAsync((async) {
      final vm = OtpViewModel(FakeAuthRepository(), email: 'minh@example.com');
      expect(vm.secondsLeft, 60);
      expect(vm.canResend, isFalse);

      async.elapse(const Duration(seconds: 42));
      expect(vm.secondsLeft, 18);
      expect(vm.canResend, isFalse);
      vm.dispose();
    });
  });

  test('resend unlocks after 60 seconds and locks again after a send', () {
    fakeAsync((async) {
      final auth = FakeAuthRepository();
      final vm = OtpViewModel(auth, email: 'minh@example.com');
      async.elapse(const Duration(seconds: 60));
      expect(vm.canResend, isTrue);

      vm.resend();
      async.flushMicrotasks();
      expect(auth.requestCount, 1);
      expect(vm.secondsLeft, 60);
      expect(vm.canResend, isFalse);
      vm.dispose();
    });
  });

  test('a failed resend stays unlocked and shows the error', () {
    fakeAsync((async) {
      final auth = FakeAuthRepository()
        ..requestResult = const Error(NetworkFailure());
      final vm = OtpViewModel(auth, email: 'minh@example.com');
      async.elapse(const Duration(seconds: 60));

      vm.resend();
      async.flushMicrotasks();
      expect(vm.failure, isA<NetworkFailure>());
      expect(vm.canResend, isTrue);
      expect(vm.secondsLeft, 0);
      vm.dispose();
    });
  });

  test('leaving during a resend does not start a new countdown', () {
    fakeAsync((async) {
      final auth = _SlowAuth();
      final vm = OtpViewModel(auth, email: 'minh@example.com');
      async.elapse(const Duration(seconds: 60));
      vm.resend();
      vm.dispose();
      auth.gate.complete();
      async.flushMicrotasks();
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('leaving the screen cancels the countdown', () {
    fakeAsync((async) {
      final vm = OtpViewModel(FakeAuthRepository(), email: 'minh@example.com');
      var ticks = 0;
      vm.addListener(() => ticks++);
      vm.dispose();
      async.elapse(const Duration(seconds: 5));
      expect(ticks, 0);
    });
  });
}

class _SlowAuth extends FakeAuthRepository {
  final gate = Completer<void>();

  @override
  Future<Result<void>> requestEmailOtp(String email) async {
    requestCount += 1;
    lastEmail = email;
    await gate.future;
    return requestResult;
  }
}
