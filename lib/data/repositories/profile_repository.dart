import 'dart:async';
import 'dart:io';

import 'package:harness_app/config/request_timeout.dart';
import 'package:harness_app/data/services/supabase_service.dart';
import 'package:harness_app/domain/models/city.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/domain/models/salary.dart';
import 'package:harness_app/domain/models/skill.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';
import 'package:http/http.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProfileRepository {
  Future<Result<Profile>> loadMyProfile();

  Future<Result<List<City>>> loadCities();

  /// `values` holds only the columns the edit screen changes.
  Future<Result<void>> saveMyProfile(Map<String, dynamic> values);

  Future<Result<List<Skill>>> loadMySkills();

  Future<Result<Skill>> addSkill(String name);

  Future<Result<void>> deleteSkill(String id);

  Future<Result<List<SalaryRole>>> loadSalaryRoles();

  Future<Result<SalaryAggregate>> salaryAggregate({
    required int roleId,
    required int cityId,
    required SeniorityLevel seniority,
  });

  Future<Result<SalaryEntry>> addSalaryEntry({
    required int roleId,
    required int cityId,
    required SeniorityLevel seniority,
    required int grossMonthlyVnd,
  });

  /// No saved answer is treated as not granted.
  Future<Result<bool>> loadAnalysisConsent();

  Future<Result<void>> setAnalysisConsent(bool granted);
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._service);

  static const _columns =
      'id, display_name, bio, city_id, seniority, contact_type, contact_value, '
      'contact_visible, visibility';

  final SupabaseService _service;

  @override
  Future<Result<Profile>> loadMyProfile() {
    return _guard(
      () async => Profile.fromJson(await _service.selectOwnProfile(_columns)),
    );
  }

  @override
  Future<Result<List<City>>> loadCities() {
    return _guard(() async {
      final rows = await _service.selectCities();
      return rows.map(City.fromJson).toList();
    });
  }

  @override
  Future<Result<void>> saveMyProfile(Map<String, dynamic> values) {
    return _guard(() => _service.updateOwnProfile(values));
  }

  @override
  Future<Result<List<Skill>>> loadMySkills() {
    return _guard(() async {
      final rows = await _service.selectOwnSkills();
      return rows.map(Skill.fromJson).toList();
    });
  }

  @override
  Future<Result<Skill>> addSkill(String name) {
    return _guard(
      () async => Skill.fromJson(await _service.insertOwnSkill(name)),
    );
  }

  @override
  Future<Result<void>> deleteSkill(String id) {
    return _guard(() => _service.deleteOwnSkill(id));
  }

  @override
  Future<Result<List<SalaryRole>>> loadSalaryRoles() {
    return _guard(() async {
      final rows = await _service.selectSalaryRoles();
      return rows.map(SalaryRole.fromJson).toList();
    });
  }

  @override
  Future<Result<SalaryAggregate>> salaryAggregate({
    required int roleId,
    required int cityId,
    required SeniorityLevel seniority,
  }) {
    return _guard(() async {
      final row = await _service.salaryAggregate(
        roleId: roleId,
        cityId: cityId,
        seniority: seniority.name,
      );
      return SalaryAggregate.fromJson(row);
    });
  }

  @override
  Future<Result<SalaryEntry>> addSalaryEntry({
    required int roleId,
    required int cityId,
    required SeniorityLevel seniority,
    required int grossMonthlyVnd,
  }) {
    return _guard(() async {
      final row = await _service.insertSalaryEntry(
        roleId: roleId,
        cityId: cityId,
        seniority: seniority.name,
        grossMonthlyVnd: grossMonthlyVnd,
      );
      return SalaryEntry.fromJson(row);
    });
  }

  @override
  Future<Result<bool>> loadAnalysisConsent() {
    return _guard(_service.selectOwnConsent);
  }

  @override
  Future<Result<void>> setAnalysisConsent(bool granted) {
    return _guard(() => _service.upsertOwnConsent(granted));
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action().timeout(requestTimeout));
    } on SocketException {
      return Error(const NetworkFailure());
    } on HandshakeException {
      return Error(const NetworkFailure());
    } on ClientException {
      return Error(const NetworkFailure());
    } on TimeoutException {
      return Error(const NetworkFailure());
    } on PostgrestException catch (exception) {
      if (exception.code == '23514') {
        return Error(const ValidationFailure('check_violation'));
      }
      if (exception.code == '23505') {
        return Error(const ValidationFailure('duplicate'));
      }
      if (exception.message.contains('CONTRIBUTION_REQUIRED')) {
        return Error(const ValidationFailure('contribution_required'));
      }
      return Error(const ServerFailure());
    } catch (_) {
      return Error(const ServerFailure());
    }
  }
}
