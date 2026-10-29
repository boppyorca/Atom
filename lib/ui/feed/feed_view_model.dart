import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/models/community_post.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

class FeedViewModel extends ChangeNotifier {
  FeedViewModel(this._repository);

  final ProfileRepository _repository;
  bool loading = false;
  String draft = '';
  String? notice;
  AppFailure? failure;
  List<CommunityPost> posts = const [];

  Future<void> load() async {
    loading = true;
    failure = null;
    notifyListeners();
    final result = await _repository.loadFeed();
    loading = false;
    if (result is Ok<List<CommunityPost>>) {
      posts = result.value;
    } else if (result is Error<List<CommunityPost>>) {
      failure = result.failure;
    }
    notifyListeners();
  }

  Future<bool> publish() async {
    final text = draft.trim();
    if (text.isEmpty) return false;
    final result = await _repository.publishPost(text);
    if (result is Error<void>) {
      failure = result.failure;
      notice = null;
      notifyListeners();
      return false;
    }
    draft = '';
    notice = 'posted';
    await load();
    return true;
  }

  Future<bool> like(String postId) async {
    final result = await _repository.toggleLike(postId);
    if (result is Error<void>) {
      failure = result.failure;
      notifyListeners();
      return false;
    }
    await load();
    return true;
  }

  Future<bool> comment(String postId, String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return false;
    final result = await _repository.commentOnPost(postId, clean);
    if (result is Error<void>) {
      failure = result.failure;
      notice = null;
      notifyListeners();
      return false;
    }
    notice = 'commented';
    notifyListeners();
    return true;
  }

  Future<bool> report(String postId, {required bool confirmed}) async {
    if (!confirmed) return false;
    final result = await _repository.reportPost(postId, 'spam');
    if (result is Error<void>) {
      failure = result.failure;
      notice = null;
      notifyListeners();
      return false;
    }
    notice = 'reported';
    notifyListeners();
    return true;
  }
}
