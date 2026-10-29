import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/domain/models/app_notice.dart';
import 'package:harness_app/ui/feed/feed_view_model.dart';
import 'package:harness_app/ui/notices/notices_view_model.dart';

import '../../fakes/fake_profile_repository.dart';

void main() {
  test(
    'a post needs text, a like is counted, and a report waits for confirmation',
    () async {
      final repo = FakeProfileRepository();
      final vm = FeedViewModel(repo);
      expect(await vm.publish(), isFalse);
      expect(repo.postCount, 0);
      vm.draft = 'Xin chào';
      expect(await vm.publish(), isTrue);
      expect(vm.notice, 'posted');
      expect(vm.posts, isNotEmpty);

      expect(await vm.like(vm.posts.first.id), isTrue);
      expect(repo.likeCount, 1);
      expect(await vm.comment(vm.posts.first.id, 'Hay'), isTrue);
      expect(vm.notice, 'commented');
      expect(await vm.report(vm.posts.first.id, confirmed: false), isFalse);
      expect(repo.postReportCount, 0);
      expect(await vm.report(vm.posts.first.id, confirmed: true), isTrue);
      expect(vm.notice, 'reported');
    },
  );

  test('a notice can be marked as seen', () async {
    final repo = FakeProfileRepository()
      ..notices = [const AppNotice(id: 'n1', kind: 'gap_ready', seen: false)];
    final vm = NoticesViewModel(repo);
    await vm.load();
    expect(vm.notices.single.seen, isFalse);
    await vm.markSeen('n1');
    expect(vm.notices.single.seen, isTrue);
  });
}
