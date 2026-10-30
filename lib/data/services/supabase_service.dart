import 'package:harness_app/domain/analysis/gap.dart';
import 'package:harness_app/domain/analysis/suggestion.dart';
import 'package:harness_app/domain/models/app_notice.dart';
import 'package:harness_app/domain/models/chat_turn.dart';
import 'package:harness_app/domain/models/community_post.dart';
import 'package:harness_app/domain/models/github_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService(this.client);

  final SupabaseClient client;

  Session? get currentSession => client.auth.currentSession;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<void> signInWithOtp({required String email}) {
    return client.auth.signInWithOtp(email: email);
  }

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  Future<void> signOut() => client.auth.signOut();

  String get _userId => client.auth.currentUser!.id;

  Future<Map<String, dynamic>> selectOwnProfile(String columns) {
    return client.from('profiles').select(columns).eq('id', _userId).single();
  }

  Future<void> updateOwnProfile(Map<String, dynamic> values) {
    return client.from('profiles').update(values).eq('id', _userId);
  }

  Future<List<Map<String, dynamic>>> selectCities() {
    return client
        .from('cities')
        .select('id, code, label_vi, label_en')
        .order('id');
  }

  Future<List<Map<String, dynamic>>> selectOwnSkills() {
    return client
        .from('skills')
        .select('id, name, confidence')
        .eq('profile_id', _userId)
        .order('created_at');
  }

  Future<Map<String, dynamic>> insertOwnSkill(String name) {
    return client
        .from('skills')
        .insert({'profile_id': _userId, 'name': name})
        .select('id, name, confidence')
        .single();
  }

  Future<void> deleteOwnSkill(String id) {
    return client
        .from('skills')
        .delete()
        .eq('id', id)
        .eq('profile_id', _userId);
  }

  Future<List<Map<String, dynamic>>> selectSalaryRoles() {
    return client
        .from('salary_roles')
        .select('id, code, label_vi, label_en')
        .order('id');
  }

  Future<Map<String, dynamic>> salaryAggregate({
    required int roleId,
    required int cityId,
    required String seniority,
  }) async {
    final result = await client.rpc<Map<String, dynamic>>(
      'get_salary_aggregate',
      params: {
        'p_role_id': roleId,
        'p_city_id': cityId,
        'p_seniority': seniority,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> insertSalaryEntry({
    required int roleId,
    required int cityId,
    required String seniority,
    required int grossMonthlyVnd,
  }) {
    return client
        .from('salary_entries')
        .insert({
          'profile_id': _userId,
          'role_id': roleId,
          'city_id': cityId,
          'seniority': seniority,
          'gross_monthly_vnd': grossMonthlyVnd,
        })
        .select('id, role_id, city_id, seniority, gross_monthly_vnd')
        .single();
  }

  Future<bool> selectOwnConsent() async {
    final row = await client
        .from('ai_consents')
        .select('granted')
        .eq('profile_id', _userId)
        .maybeSingle();
    if (row == null) return false;
    return row['granted'] as bool;
  }

  Future<void> upsertOwnConsent(bool granted) {
    return client.from('ai_consents').upsert({
      'profile_id': _userId,
      'granted': granted,
    });
  }

  Future<void> linkGithub() {
    return client.auth.linkIdentity(
      OAuthProvider.github,
      redirectTo: 'com.example.harnessapp://login-callback',
      scopes: 'read:user user:email',
    );
  }

  Future<void> connectGithub() {
    return client.rpc('connect_github');
  }

  Future<GithubRepoPage> listGithubRepos() async {
    final response = await client.functions.invoke(
      'github-repos',
      body: {'action': 'list'},
    );
    final data = response.data;
    final rows = data is Map ? data['repos'] : null;
    if (rows is! List) return const GithubRepoPage(connected: true, repos: []);
    return GithubRepoPage(
      connected: true,
      repos: [
        for (final row in rows)
          if (row is Map<String, dynamic>) GithubRepo.fromJson(row),
      ],
    );
  }

  Future<void> saveGithubRepos(List<String> fullNames) {
    return client.functions.invoke(
      'github-repos',
      body: {'action': 'save', 'full_names': fullNames},
    );
  }

  Future<void> disconnectGithub() {
    return client.from('github_connections').delete().eq('profile_id', _userId);
  }

  Future<({int used, int limit})> analysisQuota() async {
    final result = await client.rpc<Map<String, dynamic>>('get_ai_quota');
    final extract = Map<String, dynamic>.from(result['extract_skills'] as Map);
    return (used: extract['used'] as int, limit: extract['limit'] as int);
  }

  Future<AnalysisJob?> latestAnalysisJob() async {
    final row = await client
        .from('ai_jobs')
        .select('id, status, deadline_at, seen_at')
        .eq('profile_id', _userId)
        .eq('kind', 'extract_skills')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return AnalysisJob(
      id: row['id'] as String,
      status: row['status'] as String,
      deadline: DateTime.parse(row['deadline_at'] as String),
      seenAt: row['seen_at'] == null
          ? null
          : DateTime.parse(row['seen_at'] as String),
    );
  }

  Future<List<SkillSuggestion>> pendingSuggestions() async {
    final rows = await client
        .from('skill_suggestions')
        .select(
          'id, name, signals, evidence_ids, commit_metrics, skill_catalog(verifiability)',
        )
        .eq('profile_id', _userId)
        .eq('status', 'pending');
    final evidence = await client
        .from('evidence')
        .select('id, github_full_name, title')
        .eq('profile_id', _userId);
    final names = {
      for (final row in evidence)
        row['id'] as String:
            (row['github_full_name'] ?? row['title'] ?? '') as String,
    };
    String label(String signal) {
      final kind = signal.split(':').first;
      return switch (kind) {
        'keyword' => 'README',
        'topic' => 'topic',
        'language' => 'ngôn ngữ',
        'dependency' => 'thư viện',
        'file' => 'file',
        _ => kind,
      };
    }

    return [
      for (final row in rows)
        SkillSuggestion(
          id: row['id'] as String,
          name: row['name'] as String,
          sources: [
            for (final id in (row['evidence_ids'] as List? ?? []))
              if (names[id as String] != null && names[id]!.isNotEmpty)
                names[id]!,
            if (row['commit_metrics'] is Map)
              for (final entry in (row['commit_metrics'] as Map).entries)
                if (entry.value is Map &&
                    (entry.value as Map)['org_repo'] == true)
                  'repo tổ chức ${entry.key}',
          ],
          because: {
            for (final signal in (row['signals'] as List? ?? []))
              if (signal is String) label(signal),
          }.join(', '),
          verifiability: row['skill_catalog'] is Map
              ? (row['skill_catalog']['verifiability'] as String? ?? '')
              : '',
          historyPartial: historyWasCutShort(row['commit_metrics']),
        ),
    ];
  }

  Future<void> startAnalysis() {
    return client.functions.invoke('extract-skills', body: {});
  }

  Future<void> reviewSuggestion({required String id, required bool accept}) {
    return client.rpc(
      'review_suggestion',
      params: {'p_suggestion_id': id, 'p_accept': accept},
    );
  }

  Future<void> markAnalysisSeen() async {
    final latest = await latestAnalysisJob();
    if (latest == null) return;
    await client
        .from('ai_jobs')
        .update({'seen_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', latest.id)
        .eq('profile_id', _userId);
  }

  Future<List<Map<String, dynamic>>> selectOwnEvidence() {
    return client
        .from('evidence')
        .select('id, kind, url, title')
        .eq('profile_id', _userId)
        .inFilter('kind', ['article', 'product'])
        .order('created_at');
  }

  Future<Map<String, dynamic>> insertEvidenceLink({
    required String kind,
    required String url,
    required String title,
  }) {
    return client
        .from('evidence')
        .insert({
          'profile_id': _userId,
          'kind': kind,
          'url': url,
          'title': title,
        })
        .select('id, kind, url, title')
        .single();
  }

  Future<void> deleteEvidenceLink(String id) {
    return client
        .from('evidence')
        .delete()
        .eq('id', id)
        .eq('profile_id', _userId);
  }

  Future<void> attachEvidence({
    required String skillId,
    required String evidenceId,
  }) {
    return client.from('skill_evidence').insert({
      'skill_id': skillId,
      'evidence_id': evidenceId,
    });
  }

  Future<void> detachEvidence({
    required String skillId,
    required String evidenceId,
  }) {
    return client
        .from('skill_evidence')
        .delete()
        .eq('skill_id', skillId)
        .eq('evidence_id', evidenceId);
  }

  Future<void> deleteAccount() {
    return client.functions.invoke('delete-account', body: {'confirm': true});
  }

  Future<List<Map<String, dynamic>>> selectBlocked() async {
    final rows = await client.rpc<List<Map<String, dynamic>>>('list_blocked');
    return rows;
  }

  Future<void> insertReport(String profileId, String reason) {
    return client.from('reports').insert({
      'reporter_id': _userId,
      'profile_id': profileId,
      'reason': reason,
    });
  }

  Future<void> insertBlock(String profileId) {
    return client.from('blocks').insert({
      'blocker_id': _userId,
      'blocked_id': profileId,
    });
  }

  Future<void> deleteBlock(String profileId) {
    return client
        .from('blocks')
        .delete()
        .eq('blocker_id', _userId)
        .eq('blocked_id', profileId);
  }

  Future<({int used, int limit})> gapQuota() async {
    final result = await client.rpc<Map<String, dynamic>>('get_ai_quota');
    final gap = Map<String, dynamic>.from(result['gap_analysis'] as Map);
    return (used: gap['used'] as int, limit: gap['limit'] as int);
  }

  Future<GapSnapshot?> latestGap() async {
    final row = await client
        .from('ai_jobs')
        .select('status, error_code, result')
        .eq('profile_id', _userId)
        .eq('kind', 'gap_analysis')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    final result = row['result'];
    if (result is! Map) {
      return GapSnapshot(
        status: row['status'] as String,
        errorCode: row['error_code'] as String?,
      );
    }
    final have = result['have'];
    final missing = result['missing'];
    return GapSnapshot(
      status: result['status'] as String? ?? row['status'] as String,
      errorCode: row['error_code'] as String?,
      have: [
        if (have is List)
          for (final item in have)
            if (item is Map)
              GapItem(
                skill: item['skill'] as String? ?? '',
                confidence: item['confidence'] as String?,
              ),
      ],
      missing: [
        if (missing is List)
          for (final item in missing)
            if (item is Map)
              GapItem(
                skill: item['skill'] as String? ?? '',
                suggestionVi: (item['suggestion'] as Map?)?['vi'] as String?,
                suggestionEn: (item['suggestion'] as Map?)?['en'] as String?,
              ),
      ],
    );
  }

  Future<void> startGap(String description) {
    return client.functions.invoke(
      'analyze-gap',
      body: {'job_description': description},
    );
  }

  Future<List<CommunityPost>> listFeed() async {
    final result = await client.rpc<List<dynamic>>('list_feed');
    return [
      for (final row in result)
        if (row is Map)
          CommunityPost(
            id: row['id'] as String,
            authorName: row['author_name'] as String? ?? '',
            body: row['body'] as String? ?? '',
            likeCount: (row['like_count'] as num?)?.toInt() ?? 0,
            liked: row['liked'] == true,
          ),
    ];
  }

  Future<void> addPost(String body) {
    return client.rpc('add_post', params: {'p_body': body});
  }

  Future<void> addComment(String postId, String body) {
    return client.rpc(
      'add_comment',
      params: {'p_post_id': postId, 'p_body': body},
    );
  }

  Future<void> toggleLike(String postId) {
    return client.rpc('toggle_like', params: {'p_post_id': postId});
  }

  Future<void> reportPost(String postId, String reason) {
    return client.rpc(
      'report_post',
      params: {'p_post_id': postId, 'p_reason': reason},
    );
  }

  Future<List<AppNotice>> listNotices() async {
    final rows = await client
        .from('notices')
        .select('id, kind, seen_at')
        .order('created_at', ascending: false);
    return [
      for (final row in rows)
        AppNotice(
          id: row['id'] as String,
          kind: row['kind'] as String,
          seen: row['seen_at'] != null,
        ),
    ];
  }

  Future<void> markNoticeSeen(String id) {
    return client
        .from('notices')
        .update({'seen_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  Future<List<ChatTurn>> listChat() async {
    final rows = await client
        .from('chat_messages')
        .select(
          'id, role, body, provider, chat_proposals(id, title, detail, status)',
        )
        .order('created_at');
    return [
      for (final row in rows)
        ChatTurn(
          id: row['id'] as String,
          role: row['role'] as String,
          body: row['body'] as String,
          provider: row['provider'] as String?,
          proposals: [
            if (row['chat_proposals'] is List)
              for (final item in row['chat_proposals'] as List)
                if (item is Map)
                  ChatProposal(
                    id: item['id'] as String,
                    title: item['title'] as String? ?? '',
                    detail: item['detail'] as String? ?? '',
                    status: item['status'] as String? ?? 'pending',
                  ),
          ],
        ),
    ];
  }

  Future<void> askChat(String text) {
    return client.functions.invoke(
      'chat-ask',
      body: {'action': 'ask', 'text': text},
    );
  }

  Future<void> reviewChatProposal(String id, bool accept) {
    return client.rpc(
      'review_chat_proposal',
      params: {'p_id': id, 'p_accept': accept},
    );
  }

  Future<void> trainLocalChat() {
    return client.functions.invoke('chat-ask', body: {'action': 'train'});
  }
}
