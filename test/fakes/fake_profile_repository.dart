import 'dart:async';

import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/models/city.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/ui/core/result.dart';

const fakeCities = [
  City(id: 1, code: 'hn', labelVi: 'Hà Nội', labelEn: 'Hanoi'),
  City(
    id: 2,
    code: 'hcm',
    labelVi: 'TP. Hồ Chí Minh',
    labelEn: 'Ho Chi Minh City',
  ),
];

class FakeProfileRepository implements ProfileRepository {
  Profile profile = const Profile(id: 'me', displayName: 'Minh');
  Result<void>? loadError;
  Result<void>? saveError;
  int saveCount = 0;
  Completer<void>? loadGate;

  @override
  Future<Result<Profile>> loadMyProfile() async {
    await loadGate?.future;
    final error = loadError;
    if (error is Error<void>) return Error(error.failure);
    return Ok(profile);
  }

  @override
  Future<Result<List<City>>> loadCities() async {
    final error = loadError;
    if (error is Error<void>) return Error(error.failure);
    return const Ok(fakeCities);
  }

  @override
  Future<Result<void>> saveMyProfile(Profile profile) async {
    saveCount += 1;
    final error = saveError;
    if (error is Error<void>) return error;
    this.profile = profile;
    return const Ok(null);
  }
}
