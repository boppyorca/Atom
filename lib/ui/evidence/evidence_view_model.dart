import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/models/evidence.dart';
import 'package:harness_app/domain/models/skill.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

class EvidenceViewModel extends ChangeNotifier {
  EvidenceViewModel(this._repository);

  final ProfileRepository _repository;

  List<EvidenceLink> links = const [];
  List<Skill> skills = const [];
  EvidenceKind kind = EvidenceKind.article;
  String url = '';
  String title = '';
  AppFailure? failure;
  bool loading = false;

  Future<void> load() async {
    loading = true;
    failure = null;
    notifyListeners();
    final linksResult = await _repository.loadMyEvidence();
    final skillsResult = await _repository.loadMySkills();
    loading = false;
    if (linksResult is Ok<List<EvidenceLink>>) {
      links = List<EvidenceLink>.of(linksResult.value);
    }
    if (skillsResult is Ok<List<Skill>>) {
      skills = List<Skill>.of(skillsResult.value);
    }
    if (linksResult is Error<List<EvidenceLink>>) {
      failure = linksResult.failure;
    }
    notifyListeners();
  }

  Future<bool> add() async {
    final trimmedUrl = url.trim();
    final trimmedTitle = title.trim();
    if (!isValidEvidenceUrl(trimmedUrl) || trimmedTitle.isEmpty) {
      failure = const ValidationFailure('invalid_url');
      notifyListeners();
      return false;
    }
    if (links.length >= 10) {
      failure = const ValidationFailure('evidence_limit');
      notifyListeners();
      return false;
    }
    final result = await _repository.addEvidenceLink(
      kind: kind,
      url: trimmedUrl,
      title: trimmedTitle,
    );
    if (result is Error<EvidenceLink>) {
      failure = result.failure;
      notifyListeners();
      return false;
    }
    if (result is Ok<EvidenceLink>) {
      links = [...links, result.value];
      url = '';
      title = '';
      failure = null;
    }
    notifyListeners();
    return true;
  }

  Future<void> remove(EvidenceLink link) async {
    final result = await _repository.deleteEvidenceLink(link.id);
    if (result is Ok<void>) {
      links = links.where((item) => item.id != link.id).toList();
      failure = null;
      notifyListeners();
    }
  }

  Future<bool> attach(Skill skill, EvidenceLink link) async {
    final result = await _repository.attachEvidence(
      skillId: skill.id,
      evidenceId: link.id,
    );
    if (result is Error<void>) {
      failure = result.failure;
      notifyListeners();
      return false;
    }
    if (skill.confidence == SkillConfidence.selfClaimed) {
      skills = [
        for (final item in skills)
          if (item.id == skill.id)
            Skill(
              id: item.id,
              name: item.name,
              confidence: SkillConfidence.evidenced,
            )
          else
            item,
      ];
    }
    notifyListeners();
    return true;
  }
}
