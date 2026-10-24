import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/analysis/skill_dictionary.dart';
import 'package:harness_app/domain/models/skill.dart';
import 'package:harness_app/ui/core/result.dart';

class JobCompareViewModel extends ChangeNotifier {
  JobCompareViewModel(this._repository);

  final ProfileRepository _repository;

  List<Skill> skills = const [];
  String job = '';
  JobSkillGroup? group;
  bool tooLong = false;
  bool full = false;
  String? claimed;

  Future<void> load() async {
    final result = await _repository.loadMySkills();
    if (result is Ok<List<Skill>>) {
      skills = result.value;
      notifyListeners();
    }
  }

  void compare() {
    tooLong = false;
    full = false;
    claimed = null;
    try {
      group = skillsInJob(job, skills.map((skill) => skill.name));
    } on JobTooLongException {
      group = null;
      tooLong = true;
    }
    notifyListeners();
  }

  Future<bool> claim(String name) async {
    if (skills.length >= 50) {
      full = true;
      notifyListeners();
      return false;
    }
    final result = await _repository.addSkill(name);
    if (result is! Ok<Skill>) return false;
    skills = [...skills, result.value];
    claimed = name;
    compare();
    return true;
  }
}
