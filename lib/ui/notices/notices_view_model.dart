import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/models/app_notice.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

class NoticesViewModel extends ChangeNotifier {
  NoticesViewModel(this._repository);

  final ProfileRepository _repository;
  bool loading = false;
  AppFailure? failure;
  List<AppNotice> notices = const [];

  Future<void> load() async {
    loading = true;
    failure = null;
    notifyListeners();
    final result = await _repository.loadNotices();
    loading = false;
    if (result is Ok<List<AppNotice>>) {
      notices = result.value;
    } else if (result is Error<List<AppNotice>>) {
      failure = result.failure;
    }
    notifyListeners();
  }

  Future<void> markSeen(String id) async {
    final result = await _repository.markNoticeSeen(id);
    if (result is Error<void>) {
      failure = result.failure;
      notifyListeners();
      return;
    }
    notices = [
      for (final notice in notices)
        if (notice.id == id)
          AppNotice(id: notice.id, kind: notice.kind, seen: true)
        else
          notice,
    ];
    notifyListeners();
  }
}
