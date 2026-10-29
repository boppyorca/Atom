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

  Future<bool> setPublic(bool isPublic) async {
    final current = profile;
    if (current == null) return false;
    final result = await _repository.setProfileVisibility(isPublic);
    if (result is Error<void>) {
      failure = result.failure;
      notifyListeners();
      return false;
    }
    profile = Profile(
      id: current.id,
      displayName: current.displayName,
      bio: current.bio,
      cityId: current.cityId,
      seniority: current.seniority,
      contactType: current.contactType,
      contactValue: current.contactValue,
      contactVisible: current.contactVisible,
      visibility: isPublic
          ? ProfileVisibility.public
          : ProfileVisibility.private,
    );
    failure = null;
    notifyListeners();
    return true;
  }
}
