import 'dart:async';
import 'dart:io';

import 'package:harness_app/config/request_timeout.dart';
import 'package:harness_app/data/services/supabase_service.dart';
import 'package:harness_app/domain/models/city.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';
import 'package:http/http.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProfileRepository {
  Future<Result<Profile>> loadMyProfile();

  Future<Result<List<City>>> loadCities();

  /// `values` holds only the columns the edit screen changes.
  Future<Result<void>> saveMyProfile(Map<String, dynamic> values);
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
      return Error(const ServerFailure());
    } catch (_) {
      return Error(const ServerFailure());
    }
  }
}
