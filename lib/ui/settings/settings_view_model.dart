import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/auth_repository.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._authRepository);

  final AuthRepository _authRepository;

  bool running = false;
  AppFailure? failure;

  Future<void> signOut() async {
    if (running) return;
    running = true;
    failure = null;
    notifyListeners();
    final result = await _authRepository.signOut();
    running = false;
    if (result is Error<void>) failure = result.failure;
    notifyListeners();
  }
}
