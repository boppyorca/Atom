import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/models/blocked_person.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

class SafetyViewModel extends ChangeNotifier {
  SafetyViewModel(this._repository);

  final ProfileRepository _repository;
  bool loading = false;
  String? notice;
  AppFailure? failure;
  List<BlockedPerson> blocked = const [];

  Future<void> load() async {
    loading = true;
    failure = null;
    notifyListeners();
    final result = await _repository.loadBlocked();
    loading = false;
    if (result is Ok<List<BlockedPerson>>) {
      blocked = result.value;
    } else if (result is Error<List<BlockedPerson>>) {
      failure = result.failure;
    }
    notifyListeners();
  }

  Future<bool> report({
    required String profileId,
    required String reason,
    required bool confirmed,
  }) async {
    if (!confirmed) return false;
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      failure = const ValidationFailure('reason_required');
      notifyListeners();
      return false;
    }
    final result = await _repository.reportProfile(profileId, trimmed);
    if (result is Error<void>) {
      failure = result.failure;
      notice = null;
      notifyListeners();
      return false;
    }
    failure = null;
    notice = 'reported';
    notifyListeners();
    return true;
  }

  Future<bool> block(String profileId, {required bool confirmed}) async {
    if (!confirmed) return false;
    final result = await _repository.blockProfile(profileId);
    if (result is Error<void>) {
      failure = result.failure;
      notice = null;
      notifyListeners();
      return false;
    }
    failure = null;
    notice = 'blocked';
    notifyListeners();
    return true;
  }

  Future<bool> unblock(String profileId, {required bool confirmed}) async {
    if (!confirmed) return false;
    final result = await _repository.unblockProfile(profileId);
    if (result is Error<void>) {
      failure = result.failure;
      notice = null;
      notifyListeners();
      return false;
    }
    blocked = [
      for (final person in blocked)
        if (person.id != profileId) person,
    ];
    failure = null;
    notice = 'unblocked';
    notifyListeners();
    return true;
  }
}
