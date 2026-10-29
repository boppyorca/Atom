import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/domain/models/chat_turn.dart';
import 'package:harness_app/ui/chat/chat_view_model.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

import '../../fakes/fake_profile_repository.dart';

void main() {
  test('an empty question is not sent', () async {
    final repo = FakeProfileRepository();
    final vm = ChatViewModel(repo);
    expect(await vm.send(), isFalse);
    expect(repo.chatAsks, 0);
  });

  test(
    'accept and reject are saved and the home model is trained again',
    () async {
      final repo = FakeProfileRepository()
        ..chatTurns = [
          const ChatTurn(
            id: 'm1',
            role: 'assistant',
            body: 'Bạn đã có Flutter.',
            provider: 'ollama',
            proposals: [
              ChatProposal(
                id: 'p1',
                title: 'CI/CD',
                detail: 'Thêm một bước.',
                status: 'pending',
              ),
            ],
          ),
        ];
      final vm = ChatViewModel(repo);
      await vm.load();
      await vm.review(vm.turns.single.proposals.single, true);
      expect(vm.turns.single.proposals.single.status, 'accepted');
      expect(repo.trainCount, 1);
    },
  );

  test('when every model is silent the screen can retry', () async {
    final repo = FakeProfileRepository()
      ..chatResult = const Error(ValidationFailure('chat_unavailable'));
    final vm = ChatViewModel(repo)..draft = 'Mình còn thiếu gì?';
    expect(await vm.send(), isFalse);
    expect((vm.failure! as ValidationFailure).code, 'chat_unavailable');
    expect(repo.chatAsks, 1);
  });
}
