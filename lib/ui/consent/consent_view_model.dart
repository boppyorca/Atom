import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/routing/routes.dart';
import 'package:harness_app/ui/core/result.dart';

class ConsentViewModel extends ChangeNotifier {
  ConsentViewModel(this._repository);

  final ProfileRepository _repository;
  bool granted = false;
  int _choice = 0;

  /// Where the analysis button goes. Analysis itself is a later ticket.
  String? get analysisDestination => granted ? null : Routes.aiConsent;

  Future<void> load() async {
    final choice = _choice;
    final result = await _repository.loadAnalysisConsent();
    if (choice != _choice || result is! Ok<bool>) return;
    granted = result.value;
    notifyListeners();
  }

  Future<void> choose(bool value) async {
    _choice += 1;
    final previous = granted;
    granted = value;
    notifyListeners();
    final result = await _repository.setAnalysisConsent(value);
    if (result is Error<void>) {
      granted = previous;
      notifyListeners();
    }
  }
}
