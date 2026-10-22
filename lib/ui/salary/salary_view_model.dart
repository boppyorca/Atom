import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/models/city.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/domain/models/salary.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

class SalaryViewModel extends ChangeNotifier {
  SalaryViewModel(this._repository);

  final ProfileRepository _repository;

  List<SalaryRole> roles = const [];
  List<City> cities = const [];
  int? roleId;
  int? cityId;
  SeniorityLevel? seniority;
  SalaryAggregate? aggregate;
  bool loading = false;
  AppFailure? failure;

  Future<void> load() async {
    loading = true;
    failure = null;
    notifyListeners();
    final rolesResult = await _repository.loadSalaryRoles();
    final citiesResult = await _repository.loadCities();
    loading = false;
    switch (rolesResult) {
      case Ok(:final value):
        roles = value;
      case Error(:final failure):
        this.failure = failure;
    }
    switch (citiesResult) {
      case Ok(:final value):
        cities = value;
      case Error(:final failure):
        this.failure = failure;
    }
    notifyListeners();
  }

  Future<void> lookup() async {
    final role = roleId;
    final city = cityId;
    final level = seniority;
    if (role == null || city == null || level == null) {
      failure = const ValidationFailure('required');
      notifyListeners();
      return;
    }
    loading = true;
    failure = null;
    notifyListeners();
    final result = await _repository.salaryAggregate(
      roleId: role,
      cityId: city,
      seniority: level,
    );
    loading = false;
    switch (result) {
      case Ok(:final value):
        aggregate = value;
      case Error(:final failure):
        aggregate = null;
        this.failure = failure;
    }
    notifyListeners();
  }
}
