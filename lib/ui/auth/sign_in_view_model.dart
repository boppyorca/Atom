import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/auth_repository.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

class SignInViewModel extends ChangeNotifier {
  SignInViewModel(this._authRepository);

  final AuthRepository _authRepository;

  static final _emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  String email = '';
  bool emailFormatError = false;
  bool running = false;
  AppFailure? failure;

  Future<bool> submit() async {
    failure = null;
    emailFormatError = !_emailPattern.hasMatch(email.trim());
    notifyListeners();
    if (emailFormatError || running) return false;

    running = true;
    notifyListeners();
    final result = await _authRepository.requestEmailOtp(email.trim());
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
}
