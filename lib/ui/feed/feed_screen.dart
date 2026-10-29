import 'package:flutter/material.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:harness_app/ui/core/widgets/error_view.dart';
import 'package:harness_app/ui/feed/feed_view_model.dart';
import 'package:provider/provider.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<FeedViewModel>();
    if (vm.loading && vm.posts.isEmpty && vm.failure != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.feedTitle)),
        body: ErrorView(failure: vm.failure!, onRetry: vm.load),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          TextField(
            decoration: InputDecoration(labelText: l10n.feedHint),
            minLines: 2,
            maxLines: 4,
            onChanged: (value) => vm.draft = value,
          ),
          const SizedBox(height: AppSpacing.space2),
          FilledButton(onPressed: vm.publish, child: Text(l10n.feedPublish)),
          if (vm.notice == 'posted') Text(l10n.feedPosted),
          if (vm.notice == 'reported') Text(l10n.feedReported),
          if (vm.notice == 'commented') Text(l10n.feedCommented),
          const SizedBox(height: AppSpacing.space4),
          if (vm.posts.isEmpty) Text(l10n.feedEmpty),
          for (final post in vm.posts) ...[
            Text(post.authorName),
            Text(post.body),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => vm.like(post.id),
                  child: Text(l10n.feedLike(post.likeCount)),
                ),
                const SizedBox(width: AppSpacing.space2),
                OutlinedButton(
                  onPressed: () => vm.report(post.id, confirmed: true),
                  child: Text(l10n.feedReport),
                ),
              ],
            ),
            TextField(
              decoration: InputDecoration(labelText: l10n.feedComment),
              onSubmitted: (value) => vm.comment(post.id, value),
            ),
            const SizedBox(height: AppSpacing.space4),
          ],
        ],
      ),
    );
  }
}
