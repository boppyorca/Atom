import 'package:flutter/material.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/chat/chat_view_model.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:harness_app/ui/core/widgets/error_view.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<ChatViewModel>();
    if (vm.loading && vm.turns.isEmpty && vm.failure is NetworkFailure) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.chatTitle)),
        body: ErrorView(failure: vm.failure!, onRetry: vm.load),
      );
    }
    final status = switch (vm.turns.reversed
        .where((turn) => turn.role == 'assistant')
        .map((turn) => turn.provider)
        .whereType<String>()
        .cast<String?>()
        .firstOrNull) {
      'groq' => l10n.chatAskedGroq,
      'zai' => l10n.chatAskedZai,
      'ollama' => l10n.chatAskedHome,
      _ => l10n.chatAskHome,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text(vm.sending ? l10n.chatAskHome : status),
          if (vm.turns.isEmpty) Text(l10n.chatEmpty),
          if (vm.failure is ValidationFailure &&
              (vm.failure! as ValidationFailure).code == 'chat_unavailable')
            Text(l10n.chatUnavailable),
          if (vm.failure is ValidationFailure &&
              (vm.failure! as ValidationFailure).code == 'quota_exceeded')
            Text(l10n.chatQuota),
          for (final turn in vm.turns) ...[
            Text(turn.role == 'user' ? l10n.chatYou : l10n.chatAgent),
            Text(turn.body),
            for (final proposal in turn.proposals) ...[
              Text(proposal.title),
              if (proposal.detail.isNotEmpty) Text(proposal.detail),
              if (proposal.status == 'pending')
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => vm.review(proposal, false),
                      child: Text(l10n.suggestionReject),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    FilledButton(
                      onPressed: () => vm.review(proposal, true),
                      child: Text(l10n.suggestionAccept),
                    ),
                  ],
                )
              else
                Text(
                  proposal.status == 'accepted'
                      ? l10n.chatAccepted
                      : l10n.chatRejected,
                ),
            ],
          ],
          TextField(
            decoration: InputDecoration(labelText: l10n.chatHint),
            minLines: 2,
            maxLines: 6,
            onChanged: (value) => vm.draft = value,
          ),
          const SizedBox(height: AppSpacing.space2),
          FilledButton(
            onPressed: vm.sending ? null : vm.send,
            child: Text(l10n.chatSend),
          ),
          if (vm.failure is ValidationFailure &&
              (vm.failure! as ValidationFailure).code == 'chat_unavailable')
            OutlinedButton(onPressed: vm.send, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}
