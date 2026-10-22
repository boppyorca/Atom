import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/routing/routes.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:harness_app/ui/core/widgets/busy_button.dart';
import 'package:harness_app/ui/core/widgets/error_view.dart';
import 'package:harness_app/ui/salary/salary_view_model.dart';
import 'package:harness_app/domain/models/salary.dart';
import 'package:provider/provider.dart';

class SalaryScreen extends StatelessWidget {
  const SalaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<SalaryViewModel>();
    final language = Localizations.localeOf(context).languageCode;
    if (vm.loading && vm.roles.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.salaryTitle)),
        body: Center(child: Text(l10n.loading)),
      );
    }
    if (vm.failure != null && vm.roles.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.salaryTitle)),
        body: ErrorView(failure: vm.failure!, onRetry: vm.load),
      );
    }
    final aggregate = vm.aggregate;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.salaryTitle)),
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
          BusyButton(label: l10n.salaryLookup, onPressed: vm.lookup),
          const SizedBox(height: AppSpacing.space4),
          if (aggregate != null && aggregate.insufficient)
            Text(l10n.salaryInsufficient)
          else if (aggregate != null)
            Text(
              '${l10n.salaryMedian}: ${formatVnd(aggregate.median!)} ₫\n'
              '${l10n.salaryRange}: ${formatVnd(aggregate.p25!)} – ${formatVnd(aggregate.p75!)} ₫',
            ),
          if (vm.failure is ValidationFailure &&
              (vm.failure! as ValidationFailure).code ==
                  'contribution_required')
            Text(l10n.salaryContributionRequired),
          const SizedBox(height: AppSpacing.space4),
          OutlinedButton(
            onPressed: () => context.push(Routes.salaryEntry),
            child: Text(l10n.salaryContribute),
          ),
        ],
      ),
    );
  }
}
