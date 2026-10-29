import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/analysis/suggestion.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

class SuggestionsViewModel extends ChangeNotifier {
  SuggestionsViewModel(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ProfileRepository _repository;
  final DateTime Function() _now;
  bool loading = false;
  bool running = false;
  bool unseen = false;
  AppFailure? failure;
  String? jobStatus;
  int used = 0;
  int limit = 3;
  List<SkillSuggestion> suggestions = [];

  Future<void> load() async {
    loading = true;
    failure = null;
    notifyListeners();
    final quota = await _repository.loadAnalysisQuota();
    final job = await _repository.loadLatestAnalysisJob();
    final pending = await _repository.loadPendingSuggestions();
    loading = false;
    if (quota is Error<({int used, int limit})>) {
      failure = quota.failure;
    } else if (job is Error<AnalysisJob?>) {
      failure = job.failure;
    } else if (pending is Error<List<SkillSuggestion>>) {
      failure = pending.failure;
    } else {
      final quotaValue = (quota as Ok<({int used, int limit})>).value;
      used = quotaValue.used;
      limit = quotaValue.limit;
      final latest = (job as Ok<AnalysisJob?>).value;
      if (latest == null) {
        jobStatus = null;
        unseen = false;
      } else {
        jobStatus = effectiveJobStatus(
          status: latest.status,
          deadline: latest.deadline,
          now: _now(),
        );
        unseen = latest.status == 'succeeded' && latest.seenAt == null;
      }
      suggestions = (pending as Ok<List<SkillSuggestion>>).value;
    }
    notifyListeners();
  }

  Future<bool> start() async {
    running = true;
    failure = null;
    notifyListeners();
    final result = await _repository.startAnalysis();
    running = false;
    if (result is Error<void>) {
      failure = result.failure;
      notifyListeners();
      return false;
    }
    await load();
    return failure == null;
  }

  Future<void> accept(SkillSuggestion suggestion) async {
    final result = await _repository.reviewSuggestion(suggestion.id, true);
    if (result is Error<void>) {
      failure = result.failure;
      notifyListeners();
      return;
    }
    suggestions = [
      for (final item in suggestions)
        if (item.id != suggestion.id) item,
    ];
    notifyListeners();
  }

  Future<void> reject(SkillSuggestion suggestion) async {
    final result = await _repository.reviewSuggestion(suggestion.id, false);
    if (result is Error<void>) {
      failure = result.failure;
      notifyListeners();
      return;
    }
    suggestions = [
      for (final item in suggestions)
        if (item.id != suggestion.id) item,
    ];
    notifyListeners();
  }

  Future<void> markSeen() async {
    final result = await _repository.markAnalysisSeen();
    if (result is Error<void>) return;
    unseen = false;
    notifyListeners();
  }
}
