import 'package:flutter/foundation.dart';
import 'package:harness_app/data/repositories/profile_repository.dart';
import 'package:harness_app/domain/models/chat_turn.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

class ChatViewModel extends ChangeNotifier {
  ChatViewModel(this._repository);

  final ProfileRepository _repository;
  bool loading = false;
  bool sending = false;
  String draft = '';
  AppFailure? failure;
  List<ChatTurn> turns = const [];

  Future<void> load() async {
    loading = true;
    failure = null;
    notifyListeners();
    final result = await _repository.loadChat();
    loading = false;
    if (result is Ok<List<ChatTurn>>) {
      turns = result.value;
    } else if (result is Error<List<ChatTurn>>) {
      failure = result.failure;
    }
    notifyListeners();
  }

  Future<bool> send() async {
    final text = draft.trim();
    if (text.isEmpty) return false;
    sending = true;
    failure = null;
    notifyListeners();
    final result = await _repository.askChat(text);
    sending = false;
    if (result is Error<void>) {
      failure = result.failure;
      notifyListeners();
      return false;
    }
    draft = '';
    await load();
    return failure == null;
  }

  Future<void> review(ChatProposal proposal, bool accept) async {
    if (proposal.status != 'pending') return;
    final result = await _repository.reviewChatProposal(proposal.id, accept);
    if (result is Error<void>) {
      failure = result.failure;
      notifyListeners();
      return;
    }
    await _repository.trainLocalChat();
    await load();
  }
}
