import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:harness_app/ui/core/widgets/busy_button.dart';
import 'package:harness_app/ui/core/widgets/error_view.dart';
import 'package:harness_app/ui/salary/salary_entry_view_model.dart';
import 'package:provider/provider.dart';

class SalaryEntryScreen extends StatelessWidget {
  const SalaryEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<SalaryEntryViewModel>();
    final language = Localizations.localeOf(context).languageCode;
    if (vm.loading && vm.roles.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.salaryEntryTitle)),
        body: Center(child: Text(l10n.loading)),
      );
    }
    if (vm.failure != null && vm.roles.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.salaryEntryTitle)),
        body: ErrorView(failure: vm.failure!, onRetry: vm.load),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.salaryEntryTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          DropdownButtonFormField<int>(
            initialValue: vm.roleId,
            decoration: InputDecoration(labelText: l10n.salaryRoleLabel),
            items: [
              for (final role in vm.roles)
                DropdownMenuItem(
                  value: role.id,
                  child: Text(role.label(language)),
                ),
            ],
            onChanged: (value) => vm.roleId = value,
          ),
          const SizedBox(height: AppSpacing.space4),
          DropdownButtonFormField<int>(
            initialValue: vm.cityId,
            decoration: InputDecoration(labelText: l10n.cityLabel),
            items: [
              for (final city in vm.cities)
                DropdownMenuItem(
                  value: city.id,
                  child: Text(city.label(language)),
                ),
            ],
            onChanged: (value) => vm.cityId = value,
          ),
          const SizedBox(height: AppSpacing.space4),
          DropdownButtonFormField<SeniorityLevel>(
            initialValue: vm.seniority,
            decoration: InputDecoration(labelText: l10n.seniorityLabel),
            items: [
              for (final level in SeniorityLevel.values)
                DropdownMenuItem(
                  value: level,
                  child: Text(l10n.seniority(level.name)),
                ),
            ],
            onChanged: (value) => vm.seniority = value,
          ),
          const SizedBox(height: AppSpacing.space4),
          TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.salaryAmountLabel,
              errorText: _error(l10n, vm.failure),
            ),
            onChanged: (value) => vm.amount = value,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(l10n.salaryPrivate),
          const SizedBox(height: AppSpacing.space4),
          BusyButton(
            label: l10n.save,
            busy: vm.saving,
            onPressed: () async {
              final saved = await vm.save();
              if (saved && context.mounted) context.pop(true);
            },
          ),
        ],
      ),
    );
  }
}

String? _error(AppLocalizations l10n, AppFailure? failure) {
  if (failure is ValidationFailure && failure.code == 'required') {
    return l10n.salaryRequired;
  }
  if (failure is ValidationFailure && failure.code == 'duplicate') {
    return l10n.salaryDuplicate;
  }
  if (failure is NetworkFailure) return l10n.noConnection;
  if (failure != null) return l10n.genericError;
  return null;
}
