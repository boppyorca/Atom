import 'dart:async';

import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/analysis/suggestion.dart';
import 'package:harness_app/domain/analysis/gap.dart';
import 'package:harness_app/domain/models/app_notice.dart';
import 'package:harness_app/domain/models/blocked_person.dart';
import 'package:harness_app/domain/models/chat_turn.dart';
import 'package:harness_app/domain/models/community_post.dart';
import 'package:harness_app/domain/models/city.dart';
import 'package:harness_app/domain/models/evidence.dart';
import 'package:harness_app/domain/models/github_repo.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/domain/models/salary.dart';
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
  SalaryAggregate aggregate = const SalaryAggregate.insufficient();
  final List<SalaryRole> salaryRoles = const [
    SalaryRole(
      id: 1,
      code: 'mobile_developer',
      labelVi: 'Mobile developer',
      labelEn: 'Mobile developer',
    ),
  ];

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

  bool? storedConsent;
  Completer<void>? consentGate;

  @override
  Future<Result<List<SalaryRole>>> loadSalaryRoles() async => Ok(salaryRoles);

  @override
  Future<Result<SalaryAggregate>> salaryAggregate({
    required int roleId,
    required int cityId,
    required SeniorityLevel seniority,
  }) async => Ok(aggregate);

  @override
  Future<Result<SalaryEntry>> addSalaryEntry({
    required int roleId,
    required int cityId,
    required SeniorityLevel seniority,
    required int grossMonthlyVnd,
  }) async {
    return Ok(
      SalaryEntry(
        id: 'pay-1',
        roleId: roleId,
        cityId: cityId,
        seniority: seniority,
        grossMonthlyVnd: grossMonthlyVnd,
      ),
    );
  }

  @override
  Future<Result<bool>> loadAnalysisConsent() async {
    final seen = storedConsent ?? false;
    await consentGate?.future;
    return Ok(seen);
  }

  @override
  Future<Result<void>> setAnalysisConsent(bool granted) async {
    storedConsent = granted;
    return const Ok(null);
  }

  bool githubConnected = false;
  bool githubIdentityReady = false;
  List<GithubRepo> githubRepos = [];
  Result<void>? githubError;

  @override
  Future<Result<void>> connectGithub() async {
    final error = githubError;
    if (error is Error<void>) return error;
    return const Ok(null);
  }

  @override
  Future<Result<void>> rememberGithub() async {
    final error = githubError;
    if (error is Error<void>) return error;
    if (!githubIdentityReady) {
      return const Error(ValidationFailure('github_identity_missing'));
    }
    githubConnected = true;
    return const Ok(null);
  }

  @override
  Future<Result<GithubRepoPage>> loadGithubRepos() async {
    final error = githubError;
    if (error is Error<void>) return Error(error.failure);
    if (!githubConnected) {
      return const Error(ValidationFailure('github_not_connected'));
    }
    return Ok(GithubRepoPage(connected: true, repos: githubRepos));
  }

  @override
  Future<Result<void>> saveGithubRepos(List<String> fullNames) async {
    final error = githubError;
    if (error is Error<void>) return error;
    githubRepos = [
      for (final repo in githubRepos)
        repo.copyWith(selected: fullNames.contains(repo.fullName)),
    ];
    return const Ok(null);
  }

  @override
  Future<Result<void>> disconnectGithub() async {
    final error = githubError;
    if (error is Error<void>) return error;
    githubConnected = false;
    githubRepos = [];
    return const Ok(null);
  }

  AnalysisJob? analysisJob;
  List<SkillSuggestion> pendingSuggestionsList = [];
  int analysisUsed = 0;
  int analysisLimit = 3;

  @override
  Future<Result<({int used, int limit})>> loadAnalysisQuota() async {
    return Ok((used: analysisUsed, limit: analysisLimit));
  }

  @override
  Future<Result<AnalysisJob?>> loadLatestAnalysisJob() async {
    return Ok(analysisJob);
  }

  @override
  Future<Result<List<SkillSuggestion>>> loadPendingSuggestions() async {
    return Ok(pendingSuggestionsList);
  }

  @override
  Future<Result<void>> startAnalysis() async => const Ok(null);

  @override
  Future<Result<void>> reviewSuggestion(String id, bool accept) async {
    pendingSuggestionsList = [
      for (final item in pendingSuggestionsList)
        if (item.id != id) item,
    ];
    return const Ok(null);
  }

  @override
  Future<Result<void>> markAnalysisSeen() async {
    final job = analysisJob;
    if (job != null) {
      analysisJob = AnalysisJob(
        id: job.id,
        status: job.status,
        deadline: job.deadline,
        seenAt: DateTime.utc(2026, 10, 25),
      );
    }
    return const Ok(null);
  }

  @override
  Future<Result<void>> setProfileVisibility(bool isPublic) async {
    profile = Profile(
      id: profile.id,
      displayName: profile.displayName,
      bio: profile.bio,
      cityId: profile.cityId,
      seniority: profile.seniority,
      contactType: profile.contactType,
      contactValue: profile.contactValue,
      contactVisible: profile.contactVisible,
      visibility: isPublic
          ? ProfileVisibility.public
          : ProfileVisibility.private,
    );
    return const Ok(null);
  }

  final List<EvidenceLink> evidence = [];

  @override
  Future<Result<List<EvidenceLink>>> loadMyEvidence() async => Ok(evidence);

  @override
  Future<Result<EvidenceLink>> addEvidenceLink({
    required EvidenceKind kind,
    required String url,
    required String title,
  }) async {
    if (evidence.length >= 10) {
      return const Error(ValidationFailure('evidence_limit'));
    }
    final link = EvidenceLink(
      id: 'link-${evidence.length + 1}',
      kind: kind,
      url: url.trim(),
      title: title.trim(),
    );
    evidence.add(link);
    return Ok(link);
  }

  @override
  Future<Result<void>> deleteEvidenceLink(String id) async {
    evidence.removeWhere((link) => link.id == id);
    return const Ok(null);
  }

  @override
  Future<Result<void>> attachEvidence({
    required String skillId,
    required String evidenceId,
  }) async => const Ok(null);

  @override
  Future<Result<void>> detachEvidence({
    required String skillId,
    required String evidenceId,
  }) async => const Ok(null);

  int reportCount = 0;
  int blockCount = 0;
  List<BlockedPerson> blockedPeople = [];

  @override
  Future<Result<List<BlockedPerson>>> loadBlocked() async => Ok(blockedPeople);

  @override
  Future<Result<void>> reportProfile(String profileId, String reason) async {
    reportCount += 1;
    return const Ok(null);
  }

  @override
  Future<Result<void>> blockProfile(String profileId) async {
    blockCount += 1;
    return const Ok(null);
  }

  @override
  Future<Result<void>> unblockProfile(String profileId) async {
    blockedPeople = [
      for (final person in blockedPeople)
        if (person.id != profileId) person,
    ];
    return const Ok(null);
  }

  int gapStarts = 0;
  Result<void> gapResult = const Ok(null);
  ({int used, int limit}) gapQuotaValue = (used: 1, limit: 10);
  GapSnapshot? gapSnapshot;
  List<CommunityPost> feed = const [];
  int postCount = 0;
  int likeCount = 0;
  int commentCount = 0;
  int postReportCount = 0;
  List<AppNotice> notices = const [];

  @override
  Future<Result<({int used, int limit})>> loadGapQuota() async =>
      Ok(gapQuotaValue);

  @override
  Future<Result<GapSnapshot?>> loadLatestGap() async => Ok(gapSnapshot);

  @override
  Future<Result<void>> startGap(String description) async {
    gapStarts += 1;
    return gapResult;
  }

  @override
  Future<Result<List<CommunityPost>>> loadFeed() async => Ok(feed);

  @override
  Future<Result<void>> publishPost(String body) async {
    postCount += 1;
    feed = [
      CommunityPost(
        id: 'post-$postCount',
        authorName: 'Minh',
        body: body,
        likeCount: 0,
        liked: false,
      ),
      ...feed,
    ];
    return const Ok(null);
  }

  @override
  Future<Result<void>> commentOnPost(String postId, String body) async {
    commentCount += 1;
    return const Ok(null);
  }

  @override
  Future<Result<void>> toggleLike(String postId) async {
    likeCount += 1;
    return const Ok(null);
  }

  @override
  Future<Result<void>> reportPost(String postId, String reason) async {
    postReportCount += 1;
    return const Ok(null);
  }

  @override
  Future<Result<List<AppNotice>>> loadNotices() async => Ok(notices);

  @override
  Future<Result<void>> markNoticeSeen(String id) async => const Ok(null);

  int chatAsks = 0;
  int trainCount = 0;
  Result<void> chatResult = const Ok(null);
  List<ChatTurn> chatTurns = const [];

  @override
  Future<Result<List<ChatTurn>>> loadChat() async => Ok(chatTurns);

  @override
  Future<Result<void>> askChat(String text) async {
    chatAsks += 1;
    return chatResult;
  }

  @override
  Future<Result<void>> reviewChatProposal(String id, bool accept) async {
    chatTurns = [
      for (final turn in chatTurns)
        ChatTurn(
          id: turn.id,
          role: turn.role,
          body: turn.body,
          provider: turn.provider,
          proposals: [
            for (final proposal in turn.proposals)
              if (proposal.id == id)
                ChatProposal(
                  id: proposal.id,
                  title: proposal.title,
                  detail: proposal.detail,
                  status: accept ? 'accepted' : 'rejected',
                )
              else
                proposal,
          ],
        ),
    ];
    return const Ok(null);
  }

  @override
  Future<Result<void>> trainLocalChat() async {
    trainCount += 1;
    return const Ok(null);
  }
}
