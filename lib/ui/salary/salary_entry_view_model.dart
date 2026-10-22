import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/models/city.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/domain/models/salary.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

class SalaryEntryViewModel extends ChangeNotifier {
  SalaryEntryViewModel(this._repository);

  final ProfileRepository _repository;

  List<SalaryRole> roles = const [];
  List<City> cities = const [];
  int? roleId;
  int? cityId;
  SeniorityLevel? seniority;
  String amount = '';
  bool loading = false;
  bool saving = false;
  AppFailure? failure;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final rolesResult = await _repository.loadSalaryRoles();
    final citiesResult = await _repository.loadCities();
    loading = false;
    if (rolesResult is Ok<List<SalaryRole>>) roles = rolesResult.value;
    if (citiesResult is Ok<List<City>>) cities = citiesResult.value;
    if (rolesResult is Error<List<SalaryRole>>) failure = rolesResult.failure;
    if (citiesResult is Error<List<City>>) failure = citiesResult.failure;
    notifyListeners();
  }

  Future<bool> save() async {
    final role = roleId;
    final city = cityId;
    final level = seniority;
    final pay = int.tryParse(amount.replaceAll('.', ''));
    if (role == null || city == null || level == null || pay == null) {
      failure = const ValidationFailure('required');
      notifyListeners();
      return false;
    }
    saving = true;
    failure = null;
    notifyListeners();
    final result = await _repository.addSalaryEntry(
      roleId: role,
      cityId: city,
      seniority: level,
      grossMonthlyVnd: pay,
    );
    saving = false;
    if (result is Error<SalaryEntry>) {
      failure = result.failure;
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }
}
