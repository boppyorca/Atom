import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/auth_repository.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

class OtpViewModel extends ChangeNotifier {
  OtpViewModel(this._authRepository, {required this.email});

  final AuthRepository _authRepository;
  final String email;

  String token = '';
  bool running = false;
  AppFailure? failure;

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
    if (running) return;
    failure = null;
    running = true;
    notifyListeners();
    final result = await _authRepository.requestEmailOtp(email);
    running = false;
    if (result is Error<void>) failure = result.failure;
    notifyListeners();
  }
}
