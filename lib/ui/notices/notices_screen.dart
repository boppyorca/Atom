import 'package:flutter/material.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:harness_app/ui/core/widgets/error_view.dart';
import 'package:harness_app/ui/notices/notices_view_model.dart';
import 'package:provider/provider.dart';

class NoticesScreen extends StatelessWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<NoticesViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.noticesTitle)),
      body: vm.loading
          ? Center(child: Text(l10n.loading))
          : vm.failure != null
          ? ErrorView(failure: vm.failure!, onRetry: vm.load)
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                if (vm.notices.isEmpty) Text(l10n.noticesEmpty),
                for (final notice in vm.notices)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      notice.kind == 'gap_ready'
                          ? l10n.noticeGapReady
                          : notice.kind,
                    ),
                    trailing: notice.seen
                        ? null
                        : OutlinedButton(
                            onPressed: () => vm.markSeen(notice.id),
                            child: Text(l10n.noticesSeen),
                          ),
                  ),
              ],
            ),
    );
  }
}
