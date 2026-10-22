import 'package:flutter/material.dart';
import 'package:harness_app/data/services/locale_preference.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/settings/settings_view_model.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<SettingsViewModel>();
    final preference = context.watch<LocalePreference>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(title: Text(l10n.languageLabel)),
          RadioGroup<String>(
            groupValue: preference.locale.languageCode,
            onChanged: (value) {
              if (value != null) preference.choose(Locale(value));
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'vi',
                  title: Text(l10n.languageVietnamese),
                ),
                RadioListTile<String>(
                  value: 'en',
                  title: Text(l10n.languageEnglish),
                ),
              ],
            ),
          ),
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
