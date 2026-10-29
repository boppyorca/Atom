import 'package:flutter/material.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:harness_app/ui/core/widgets/error_view.dart';
import 'package:harness_app/ui/safety/safety_view_model.dart';
import 'package:provider/provider.dart';

class BlockedPeopleScreen extends StatelessWidget {
  const BlockedPeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<SafetyViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.blockedPeople)),
      body: vm.loading
          ? Center(child: Text(l10n.loading))
          : vm.failure != null
          ? ErrorView(failure: vm.failure!, onRetry: vm.load)
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                if (vm.notice != null) Text(l10n.blockRemoved),
                if (vm.blocked.isEmpty) Text(l10n.blockedEmpty),
                for (final person in vm.blocked)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(person.name),
                    trailing: OutlinedButton(
                      onPressed: () => vm.unblock(person.id, confirmed: true),
                      child: Text(l10n.unblock),
                    ),
                  ),
              ],
            ),
    );
  }
}

class ReportProfileScreen extends StatefulWidget {
  const ReportProfileScreen({super.key, required this.profileId});

  final String profileId;

  @override
  State<ReportProfileScreen> createState() => _ReportProfileScreenState();
}

class _ReportProfileScreenState extends State<ReportProfileScreen> {
  String _reason = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<SafetyViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportProfile)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          TextField(
            decoration: InputDecoration(labelText: l10n.reportReason),
            onChanged: (value) => _reason = value,
          ),
          const SizedBox(height: AppSpacing.space4),
          FilledButton(
            onPressed: () => vm.report(
              profileId: widget.profileId,
              reason: _reason,
              confirmed: true,
            ),
            child: Text(l10n.reportSend),
          ),
          if (vm.notice == 'reported') ...[
            const SizedBox(height: AppSpacing.space2),
            Text(l10n.reportSent),
          ],
        ],
      ),
    );
  }
}
