import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/domain/models/github_repo.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';
import 'package:harness_app/ui/github/github_repos_view_model.dart';

import '../../fakes/fake_profile_repository.dart';

GithubRepo sample(String name, {bool selected = false}) {
  return GithubRepo(
    fullName: 'minh-dev/$name',
    url: 'https://github.com/minh-dev/$name',
    isFork: false,
    selected: selected,
  );
}

void main() {
  test(
    'a dropped GitHub load shows no connection and retry loads the list',
    () async {
      final repo = FakeProfileRepository()
        ..githubError = const Error(NetworkFailure());
      final vm = GithubReposViewModel(repo);

      await vm.load();
      expect(vm.failure, isA<NetworkFailure>());

      repo
        ..githubError = null
        ..githubIdentityReady = true
        ..githubRepos = [sample('todo', selected: true)];
      await vm.load();
      expect(vm.failure, isNull);
      expect(vm.repos.single.name, 'todo');
    },
  );

  test('the 11th selected repo is refused', () {
    final vm = GithubReposViewModel(FakeProfileRepository());
    vm.repos = [
      for (var index = 0; index < 10; index++)
        sample('app-$index', selected: true),
      sample('extra'),
    ];

    vm.toggle(vm.repos.last);
    expect(vm.failure, isA<ValidationFailure>());
    expect((vm.failure! as ValidationFailure).code, 'too_many_repos');
    expect(vm.selectedCount, 10);
  });

  test(
    'opening GitHub does not record the connection until login finishes',
    () async {
      final repo = FakeProfileRepository();
      final vm = GithubReposViewModel(repo);

      expect(await vm.connect(), isFalse);
      expect(vm.connected, isFalse);

      repo.githubIdentityReady = true;
      await vm.load();
      expect(vm.connected, isTrue);
    },
  );
}
