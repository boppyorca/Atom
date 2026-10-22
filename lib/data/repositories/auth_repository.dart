import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:harness_app/data/services/supabase_service.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository extends ChangeNotifier {
  bool get isSignedIn;

  Future<Result<void>> requestEmailOtp(String email);

  Future<Result<void>> verifyEmailOtp({
    required String email,
    required String token,
  });

  Future<Result<void>> signOut();
}

class SupabaseAuthRepository extends AuthRepository {
  SupabaseAuthRepository(this._service) {
    _authSub = _service.authStateChanges.listen((_) => notifyListeners());
  }

  final SupabaseService _service;
  StreamSubscription<AuthState>? _authSub;

  @override
  bool get isSignedIn => _service.currentSession != null;

  @override
  Future<Result<void>> requestEmailOtp(String email) {
    return _guard(() => _service.signInWithOtp(email: email));
  }

  @override
  Future<Result<void>> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return _guard(() async {
      await _service.verifyEmailOtp(email: email, token: token);
    }, onAuth: (_) => const ValidationFailure('otp_invalid'));
  }

  @override
  Future<Result<void>> signOut() => _guard(_service.signOut);

  Future<Result<void>> _guard(
    Future<void> Function() action, {
    AppFailure Function(AuthException exception)? onAuth,
  }) async {
    try {
      await action();
      return const Ok(null);
    } on SocketException {
      return const Error(NetworkFailure());
    } on TimeoutException {
      return const Error(NetworkFailure());
    } on AuthRetryableFetchException {
      return const Error(NetworkFailure());
    } on AuthException catch (exception) {
      return Error(onAuth?.call(exception) ?? const ServerFailure());
    } catch (_) {
      return const Error(ServerFailure());
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
