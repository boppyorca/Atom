import 'package:flutter/material.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/settings/settings_view_model.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<SettingsViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.signOut),
            enabled: !vm.running,
            onTap: vm.signOut,
          ),
        ],
      ),
    );
  }
}
