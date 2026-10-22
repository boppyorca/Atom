import 'dart:async';

import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/models/city.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/domain/models/skill.dart';
import 'package:harness_app/ui/core/app_failure.dart';
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
  Set<String> savedKeys = const {};
  Completer<void>? loadGate;
  List<Skill> skills = [];

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
  Future<Result<void>> saveMyProfile(Map<String, dynamic> values) async {
    saveCount += 1;
    final error = saveError;
    if (error is Error<void>) return error;
    profile = Profile.fromJson({
      'id': profile.id,
      'visibility': profile.visibility.name,
      ...values,
    });
    savedKeys = values.keys.toSet();
    return const Ok(null);
  }

  @override
  Future<Result<List<Skill>>> loadMySkills() async {
    await loadGate?.future;
    final error = loadError;
    if (error is Error<void>) return Error(error.failure);
    return Ok(skills);
  }

  @override
  Future<Result<Skill>> addSkill(String name) async {
    final trimmed = name.trim();
    final normalized = trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (skills.any(
      (skill) =>
          skill.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ==
          normalized,
    )) {
      return const Error(ValidationFailure('duplicate_skill'));
    }
    final skill = Skill(
      id: 'skill-${skills.length + 1}',
      name: trimmed,
      confidence: SkillConfidence.selfClaimed,
    );
    skills = [...skills, skill];
    return Ok(skill);
  }

  @override
  Future<Result<void>> deleteSkill(String id) async {
    skills = skills.where((skill) => skill.id != id).toList();
    return const Ok(null);
  }
}
