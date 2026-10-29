import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/analysis/gap.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

class GapViewModel extends ChangeNotifier {
  GapViewModel(this._repository);

  final ProfileRepository _repository;
  bool loading = false;
  bool running = false;
  String description = '';
  int used = 0;
  int limit = 10;
  AppFailure? failure;
  GapSnapshot? snapshot;

  Future<void> load() async {
    loading = true;
    failure = null;
    notifyListeners();
    final quota = await _repository.loadGapQuota();
    final latest = await _repository.loadLatestGap();
    loading = false;
    if (quota is Error<({int used, int limit})>) {
      failure = quota.failure;
    } else if (latest is Error<GapSnapshot?>) {
      failure = latest.failure;
    } else {
      final quotaValue = (quota as Ok<({int used, int limit})>).value;
      used = quotaValue.used;
      limit = quotaValue.limit;
      snapshot = (latest as Ok<GapSnapshot?>).value;
    }
    notifyListeners();
  }

  Future<bool> start() async {
    final text = description.trim();
    if (text.isEmpty || text.length > 8000) {
      failure = const ValidationFailure('input_invalid');
      notifyListeners();
      return false;
    }
    running = true;
    failure = null;
    notifyListeners();
    final result = await _repository.startGap(text);
    running = false;
    if (result is Error<void>) {
      failure = result.failure;
      notifyListeners();
      return false;
    }
    await load();
    return failure == null;
  }
}
