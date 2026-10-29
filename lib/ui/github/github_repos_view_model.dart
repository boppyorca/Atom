import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/models/github_repo.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

class GithubReposViewModel extends ChangeNotifier {
  GithubReposViewModel(this._repository);

  final ProfileRepository _repository;
  bool loading = false;
  bool connected = false;
  bool running = false;
  AppFailure? failure;
  List<GithubRepo> repos = [];

  int get selectedCount => repos.where((repo) => repo.selected).length;

  Future<void> load() async {
    loading = true;
    failure = null;
    notifyListeners();
    final remembered = await _repository.rememberGithub();
    if (remembered is Error<void> && remembered.failure is! ValidationFailure) {
      loading = false;
      failure = remembered.failure;
      notifyListeners();
      return;
    }
    if (remembered is Error<void>) {
      loading = false;
      connected = false;
      repos = [];
      notifyListeners();
      return;
    }
    final result = await _repository.loadGithubRepos();
    loading = false;
    switch (result) {
      case Ok(:final value):
        connected = value.connected;
        repos = value.repos;
      case Error(:final failure):
        if (failure is ValidationFailure &&
            failure.code == 'github_not_connected') {
          connected = false;
          repos = [];
        } else {
          this.failure = failure;
        }
    }
    notifyListeners();
  }

  Future<bool> connect() async {
    running = true;
    failure = null;
    notifyListeners();
    final result = await _repository.connectGithub();
    running = false;
    if (result is Error<void>) {
      failure = result.failure;
      notifyListeners();
      return false;
    }
    await load();
    return connected && failure == null;
  }

  void toggle(GithubRepo repo) {
    final next = !repo.selected;
    if (next && selectedCount >= 10) {
      failure = const ValidationFailure('too_many_repos');
      notifyListeners();
      return;
    }
    failure = null;
    repos = [
      for (final item in repos)
        if (item.fullName == repo.fullName)
          item.copyWith(selected: next)
        else
          item,
    ];
    notifyListeners();
  }

  Future<bool> save() async {
    if (selectedCount > 10) {
      failure = const ValidationFailure('too_many_repos');
      notifyListeners();
      return false;
    }
    running = true;
    failure = null;
    notifyListeners();
    final result = await _repository.saveGithubRepos([
      for (final repo in repos)
        if (repo.selected) repo.fullName,
    ]);
    running = false;
    if (result is Error<void>) {
      failure = result.failure;
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> disconnect() async {
    running = true;
    failure = null;
    notifyListeners();
    final result = await _repository.disconnectGithub();
    running = false;
    if (result is Error<void>) {
      failure = result.failure;
      notifyListeners();
      return false;
    }
    connected = false;
    repos = [];
    notifyListeners();
    return true;
  }
}
