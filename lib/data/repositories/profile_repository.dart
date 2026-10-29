import 'dart:async';
import 'dart:io';

import 'package:harness_app/config/request_timeout.dart';
import 'package:harness_app/data/services/supabase_service.dart';
import 'package:harness_app/domain/analysis/suggestion.dart';
import 'package:harness_app/domain/models/city.dart';
import 'package:harness_app/domain/models/evidence.dart';
import 'package:harness_app/domain/models/github_repo.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/domain/models/salary.dart';
import 'package:harness_app/domain/models/skill.dart';
import 'package:harness_app/domain/analysis/gap.dart';
import 'package:harness_app/domain/models/app_notice.dart';
import 'package:harness_app/domain/models/blocked_person.dart';
import 'package:harness_app/domain/models/chat_turn.dart';
import 'package:harness_app/domain/models/community_post.dart';
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

  Future<Result<void>> connectGithub();

  /// Records the GitHub name after the browser login has finished.
  /// A missing GitHub login is [ValidationFailure] `github_identity_missing`.
  Future<Result<void>> rememberGithub();

  Future<Result<GithubRepoPage>> loadGithubRepos();

  Future<Result<void>> saveGithubRepos(List<String> fullNames);

  Future<Result<void>> disconnectGithub();

  Future<Result<({int used, int limit})>> loadAnalysisQuota();

  Future<Result<AnalysisJob?>> loadLatestAnalysisJob();

  Future<Result<List<SkillSuggestion>>> loadPendingSuggestions();

  Future<Result<void>> startAnalysis();

  Future<Result<void>> reviewSuggestion(String id, bool accept);

  Future<Result<void>> markAnalysisSeen();

  Future<Result<void>> setProfileVisibility(bool isPublic);

  Future<Result<List<EvidenceLink>>> loadMyEvidence();

  Future<Result<EvidenceLink>> addEvidenceLink({
    required EvidenceKind kind,
    required String url,
    required String title,
  });

  Future<Result<void>> deleteEvidenceLink(String id);

  Future<Result<void>> attachEvidence({
    required String skillId,
    required String evidenceId,
  });

  Future<Result<void>> detachEvidence({
    required String skillId,
    required String evidenceId,
  });

  Future<Result<List<BlockedPerson>>> loadBlocked();

  Future<Result<void>> reportProfile(String profileId, String reason);

  Future<Result<void>> blockProfile(String profileId);

  Future<Result<void>> unblockProfile(String profileId);

  Future<Result<({int used, int limit})>> loadGapQuota();

  Future<Result<GapSnapshot?>> loadLatestGap();

  Future<Result<void>> startGap(String description);

  Future<Result<List<CommunityPost>>> loadFeed();

  Future<Result<void>> publishPost(String body);

  Future<Result<void>> commentOnPost(String postId, String body);

  Future<Result<void>> toggleLike(String postId);

  Future<Result<void>> reportPost(String postId, String reason);

  Future<Result<List<AppNotice>>> loadNotices();

  Future<Result<void>> markNoticeSeen(String id);

  Future<Result<List<ChatTurn>>> loadChat();

  Future<Result<void>> askChat(String text);

  Future<Result<void>> reviewChatProposal(String id, bool accept);

  Future<Result<void>> trainLocalChat();
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

  @override
  Future<Result<void>> connectGithub() {
    return _guard(_service.linkGithub);
  }

  @override
  Future<Result<void>> rememberGithub() {
    return _guard(_service.connectGithub);
  }

  @override
  Future<Result<GithubRepoPage>> loadGithubRepos() {
    return _guard(_service.listGithubRepos);
  }

  @override
  Future<Result<void>> saveGithubRepos(List<String> fullNames) {
    return _guard(() => _service.saveGithubRepos(fullNames));
  }

  @override
  Future<Result<void>> disconnectGithub() {
    return _guard(_service.disconnectGithub);
  }

  @override
  Future<Result<({int used, int limit})>> loadAnalysisQuota() {
    return _guard(_service.analysisQuota);
  }

  @override
  Future<Result<AnalysisJob?>> loadLatestAnalysisJob() {
    return _guard(_service.latestAnalysisJob);
  }

  @override
  Future<Result<List<SkillSuggestion>>> loadPendingSuggestions() {
    return _guard(_service.pendingSuggestions);
  }

  @override
  Future<Result<void>> startAnalysis() {
    return _guard(_service.startAnalysis);
  }

  @override
  Future<Result<void>> reviewSuggestion(String id, bool accept) {
    return _guard(() => _service.reviewSuggestion(id: id, accept: accept));
  }

  @override
  Future<Result<void>> markAnalysisSeen() {
    return _guard(_service.markAnalysisSeen);
  }

  @override
  Future<Result<void>> setProfileVisibility(bool isPublic) {
    return _guard(
      () => _service.updateOwnProfile({
        'visibility': isPublic ? 'public' : 'private',
      }),
    );
  }

  @override
  Future<Result<List<EvidenceLink>>> loadMyEvidence() {
    return _guard(() async {
      final rows = await _service.selectOwnEvidence();
      return rows.map(EvidenceLink.fromJson).toList();
    });
  }

  @override
  Future<Result<EvidenceLink>> addEvidenceLink({
    required EvidenceKind kind,
    required String url,
    required String title,
  }) {
    return _guard(() async {
      final row = await _service.insertEvidenceLink(
        kind: kind.name,
        url: url.trim(),
        title: title.trim(),
      );
      return EvidenceLink.fromJson(row);
    });
  }

  @override
  Future<Result<void>> deleteEvidenceLink(String id) {
    return _guard(() => _service.deleteEvidenceLink(id));
  }

  @override
  Future<Result<void>> attachEvidence({
    required String skillId,
    required String evidenceId,
  }) {
    return _guard(
      () => _service.attachEvidence(skillId: skillId, evidenceId: evidenceId),
    );
  }

  @override
  Future<Result<void>> detachEvidence({
    required String skillId,
    required String evidenceId,
  }) {
    return _guard(
      () => _service.detachEvidence(skillId: skillId, evidenceId: evidenceId),
    );
  }

  @override
  Future<Result<List<BlockedPerson>>> loadBlocked() {
    return _guard(() async {
      final rows = await _service.selectBlocked();
      return [
        for (final row in rows)
          BlockedPerson(
            id: row['id'] as String,
            name: row['display_name'] as String,
          ),
      ];
    });
  }

  @override
  Future<Result<void>> reportProfile(String profileId, String reason) {
    return _guard(() => _service.insertReport(profileId, reason));
  }

  @override
  Future<Result<void>> blockProfile(String profileId) {
    return _guard(() => _service.insertBlock(profileId));
  }

  @override
  Future<Result<void>> unblockProfile(String profileId) {
    return _guard(() => _service.deleteBlock(profileId));
  }

  @override
  Future<Result<({int used, int limit})>> loadGapQuota() {
    return _guard(_service.gapQuota);
  }

  @override
  Future<Result<GapSnapshot?>> loadLatestGap() {
    return _guard(_service.latestGap);
  }

  @override
  Future<Result<void>> startGap(String description) {
    return _guard(() => _service.startGap(description));
  }

  @override
  Future<Result<List<CommunityPost>>> loadFeed() {
    return _guard(_service.listFeed);
  }

  @override
  Future<Result<void>> publishPost(String body) {
    return _guard(() => _service.addPost(body));
  }

  @override
  Future<Result<void>> commentOnPost(String postId, String body) {
    return _guard(() => _service.addComment(postId, body));
  }

  @override
  Future<Result<void>> toggleLike(String postId) {
    return _guard(() => _service.toggleLike(postId));
  }

  @override
  Future<Result<void>> reportPost(String postId, String reason) {
    return _guard(() => _service.reportPost(postId, reason));
  }

  @override
  Future<Result<List<AppNotice>>> loadNotices() {
    return _guard(_service.listNotices);
  }

  @override
  Future<Result<void>> markNoticeSeen(String id) {
    return _guard(() => _service.markNoticeSeen(id));
  }

  @override
  Future<Result<List<ChatTurn>>> loadChat() {
    return _guard(_service.listChat);
  }

  @override
  Future<Result<void>> askChat(String text) {
    return _guard(() => _service.askChat(text));
  }

  @override
  Future<Result<void>> reviewChatProposal(String id, bool accept) {
    return _guard(() => _service.reviewChatProposal(id, accept));
  }

  @override
  Future<Result<void>> trainLocalChat() {
    return _guard(_service.trainLocalChat);
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
    } on FunctionException catch (exception) {
      final details = exception.details;
      final code = details is Map ? details['code']?.toString() : null;
      if (code == 'GITHUB_NOT_CONNECTED') {
        return Error(const ValidationFailure('github_not_connected'));
      }
      if (code == 'TOO_MANY_REPOS') {
        return Error(const ValidationFailure('too_many_repos'));
      }
      if (code == 'RATE_LIMITED') {
        return Error(const ValidationFailure('github_rate_limited'));
      }
      if (code == 'NOT_FOUND') {
        return Error(const ValidationFailure('github_not_found'));
      }
      if (code == 'QUOTA_EXCEEDED') {
        return Error(const ValidationFailure('quota_exceeded'));
      }
      if (code == 'CONSENT_REQUIRED') {
        return Error(const ValidationFailure('consent_required'));
      }
      if (code == 'NO_SKILLS') {
        return Error(const ValidationFailure('no_skills'));
      }
      if (code == 'INPUT_INVALID') {
        return Error(const ValidationFailure('input_invalid'));
      }
      if (code == 'CHAT_UNAVAILABLE') {
        return Error(const ValidationFailure('chat_unavailable'));
      }
      if (code == 'GITHUB_UNAVAILABLE' || exception.status >= 500) {
        return Error(const NetworkFailure());
      }
      return Error(const ServerFailure());
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
      if (exception.message.contains('GITHUB_IDENTITY_MISSING')) {
        return Error(const ValidationFailure('github_identity_missing'));
      }
      if (exception.message.contains('EVIDENCE_LIMIT')) {
        return Error(const ValidationFailure('evidence_limit'));
      }
      return Error(const ServerFailure());
    } catch (_) {
      return Error(const ServerFailure());
    }
  }
}
