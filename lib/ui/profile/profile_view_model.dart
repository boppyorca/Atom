import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/models/city.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._repository);

  final ProfileRepository _repository;

  bool loading = false;
  AppFailure? failure;
  Profile? profile;
  City? city;

  Future<void> load() async {
    loading = true;
    failure = null;
    notifyListeners();
    final profileResult = await _repository.loadMyProfile();
    final citiesResult = await _repository.loadCities();
    loading = false;
    switch ((profileResult, citiesResult)) {
      case (Ok(value: final loaded), Ok(value: final cities)):
        profile = loaded;
        city = cities.where((c) => c.id == loaded.cityId).firstOrNull;
      case (Error(:final failure), _) || (_, Error(:final failure)):
        this.failure = failure;
    }
    notifyListeners();
  }
}
