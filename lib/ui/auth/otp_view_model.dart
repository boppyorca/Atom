import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/auth_repository.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

class OtpViewModel extends ChangeNotifier {
  OtpViewModel(this._authRepository, {required this.email}) {
    _startCooldown();
  }

  static const cooldownSeconds = 60;

  final AuthRepository _authRepository;
  final String email;

  String token = '';
  bool running = false;
  AppFailure? failure;
  int secondsLeft = cooldownSeconds;
  Timer? _timer;
  bool _disposed = false;

  bool get canResend => secondsLeft == 0 && !running;

  Future<bool> confirm() async {
    if (running) return false;
    failure = null;
    running = true;
    notifyListeners();
    final result = await _authRepository.verifyEmailOtp(
      email: email,
      token: token.trim(),
    );
    running = false;
    switch (result) {
      case Ok():
        notifyListeners();
        return true;
      case Error(:final failure):
        this.failure = failure;
        notifyListeners();
        return false;
    }
  }

  Future<void> resend() async {
    if (!canResend) return;
    failure = null;
    running = true;
    notifyListeners();
    final result = await _authRepository.requestEmailOtp(email);
    if (_disposed) return;
    running = false;
    if (result is Error<void>) {
      failure = result.failure;
    } else {
      _startCooldown();
    }
    notifyListeners();
  }

  void _startCooldown() {
    _timer?.cancel();
    secondsLeft = cooldownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      if (secondsLeft <= 1) {
        secondsLeft = 0;
        timer.cancel();
      } else {
        secondsLeft -= 1;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
