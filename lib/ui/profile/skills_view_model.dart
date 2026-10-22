import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/models/skill.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

class SkillsViewModel extends ChangeNotifier {
  SkillsViewModel(this._repository);

  final ProfileRepository _repository;

  List<Skill> skills = const [];
  bool loading = false;
  bool saving = false;
  AppFailure? failure;

  Future<void> load() async {
    loading = true;
    failure = null;
    notifyListeners();
    final result = await _repository.loadMySkills();
    loading = false;
    switch (result) {
      case Ok(:final value):
        skills = value;
      case Error(:final failure):
        this.failure = failure;
    }
    notifyListeners();
  }

  Future<bool> add(String rawName) async {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty || saving) return false;
    saving = true;
    failure = null;
    notifyListeners();
    final result = await _repository.addSkill(trimmed);
    saving = false;
    switch (result) {
      case Ok(:final value):
        skills = [...skills, value];
        notifyListeners();
        return true;
      case Error(:final failure):
        this.failure = failure;
        notifyListeners();
        return false;
    }
  }

  Future<void> delete(Skill skill) async {
    if (saving) return;
    saving = true;
    failure = null;
    notifyListeners();
    final result = await _repository.deleteSkill(skill.id);
    saving = false;
    if (result is Ok<void>) {
      skills = skills.where((item) => item.id != skill.id).toList();
    } else if (result is Error<void>) {
      failure = result.failure;
    }
    notifyListeners();
  }
}
