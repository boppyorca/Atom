import 'dart:async';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/data/services/supabase_service.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

void main() {
  final cases = <String, Object>{
    'lost connection': const SocketException('offline'),
    'secure connection failed': const HandshakeException('wifi login page'),
    'no answer in time': TimeoutException('slow'),
  };

  for (final entry in cases.entries) {
    test('${entry.key} becomes "no connection"', () async {
      final repo = SupabaseProfileRepository(_ThrowingService(entry.value));

      final result = await repo.loadMyProfile();

      expect(result, isA<Error<Profile>>());
      expect((result as Error<Profile>).failure, isA<NetworkFailure>());
    });
  }

  test(
    'a read that never answers becomes "no connection" after 10 seconds',
    () {
      final repo = SupabaseProfileRepository(_HangingService());

      late Result<Profile> result;
      // Another test file installs the widget binding, whose clock cannot be
      // fast-forwarded, so this test brings the fake clock back for itself.
      fakeAsync((time) {
        repo.loadMyProfile().then((value) => result = value);
        time.elapse(const Duration(seconds: 9));
        expect(time.pendingTimers, isNotEmpty);
        time.elapse(const Duration(seconds: 1));
        time.flushMicrotasks();
      });

      expect(result, isA<Error<Profile>>());
      expect((result as Error<Profile>).failure, isA<NetworkFailure>());
    },
  );
}

/// A server stand-in that never answers.
class _HangingService extends Fake implements SupabaseService {
  @override
  Future<Map<String, dynamic>> selectOwnProfile(String columns) =>
      Completer<Map<String, dynamic>>().future;
}

/// A server stand-in whose every read fails with [error].
class _ThrowingService extends Fake implements SupabaseService {
  _ThrowingService(this.error);

  final Object error;

  @override
  Future<Map<String, dynamic>> selectOwnProfile(String columns) =>
      Future.error(error);
}
