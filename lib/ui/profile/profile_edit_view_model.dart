import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/models/city.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

class ProfileEditViewModel extends ChangeNotifier {
  ProfileEditViewModel(this._repository);

  final ProfileRepository _repository;

  // Must match the profiles_contact_format check in the database.
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _linkedinPattern = RegExp(r'^https://(www\.)?linkedin\.com/');

  bool loading = false;
  AppFailure? loadFailure;
  List<City> cities = const [];
  Profile? _loaded;

  String displayName = '';
  String contactValue = '';
  bool nameError = false;
  bool contactError = false;
  bool saving = false;
  AppFailure? saveFailure;

  String _bio = '';
  int? _cityId;
  SeniorityLevel? _seniority;
  ContactLinkType? _contactType;
  bool _contactVisible = false;

  String get bio => _bio;
  set bio(String value) {
    _bio = value;
    notifyListeners();
  }

  int? get cityId => _cityId;
  set cityId(int? value) {
    _cityId = value;
    notifyListeners();
  }

  SeniorityLevel? get seniority => _seniority;
  set seniority(SeniorityLevel? value) {
    _seniority = value;
    notifyListeners();
  }

  ContactLinkType? get contactType => _contactType;
  set contactType(ContactLinkType? value) {
    _contactType = value;
    contactError = false;
    notifyListeners();
  }

  bool get contactVisible => _contactVisible;
  set contactVisible(bool value) {
    _contactVisible = value;
    notifyListeners();
  }

  // Postgres char_length counts code points, so count runes, not UTF-16 units.
  int get bioRemaining => Profile.maxBioLength - _bio.runes.length;
  bool get bioTooLong => bioRemaining < 0;

  Future<void> load() async {
    loading = true;
    loadFailure = null;
    notifyListeners();
    final profileResult = await _repository.loadMyProfile();
    final citiesResult = await _repository.loadCities();
    loading = false;
    switch ((profileResult, citiesResult)) {
      case (Ok(value: final profile), Ok(value: final loadedCities)):
        _loaded = profile;
        cities = loadedCities;
        displayName = profile.displayName;
        _bio = profile.bio ?? '';
        _cityId = profile.cityId;
        _seniority = profile.seniority;
        _contactType = profile.contactType;
        contactValue = profile.contactValue ?? '';
        _contactVisible = profile.contactVisible;
      case (Error(:final failure), _) || (_, Error(:final failure)):
        loadFailure = failure;
    }
    notifyListeners();
  }

  Future<bool> save() async {
    final loaded = _loaded;
    if (loaded == null || saving) return false;
    final name = displayName.trim();
    final contact = contactValue.trim();
    saveFailure = null;
    nameError =
        name.isEmpty || name.runes.length > Profile.maxDisplayNameLength;
    contactError = switch (_contactType) {
      null => false,
      ContactLinkType.email => !_emailPattern.hasMatch(contact),
      ContactLinkType.linkedin => !_linkedinPattern.hasMatch(contact),
    };
    notifyListeners();
    if (nameError || contactError || bioTooLong) return false;

    saving = true;
    notifyListeners();
    final bioText = _bio.trim();
    final values = {
      'display_name': name,
      'bio': bioText.isEmpty ? null : bioText,
      'city_id': _cityId,
      'seniority': _seniority?.name,
      'contact_type': _contactType?.name,
      'contact_value': _contactType == null ? null : contact,
      'contact_visible': _contactVisible,
    };
    final result = await _repository.saveMyProfile(values);
    saving = false;
    switch (result) {
      case Ok():
        _loaded = Profile(
          id: loaded.id,
          displayName: name,
          bio: values['bio'] as String?,
          cityId: _cityId,
          seniority: _seniority,
          contactType: _contactType,
          contactValue: values['contact_value'] as String?,
          contactVisible: _contactVisible,
          visibility: loaded.visibility,
        );
        notifyListeners();
        return true;
      case Error(:final failure):
        saveFailure = failure;
        notifyListeners();
        return false;
    }
  }
}
