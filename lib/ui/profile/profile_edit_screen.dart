import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:harness_app/ui/core/widgets/busy_button.dart';
import 'package:harness_app/ui/core/widgets/error_view.dart';
import 'package:harness_app/ui/profile/profile_edit_view_model.dart';
import 'package:provider/provider.dart';

class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<ProfileEditViewModel>();
    final loadFailure = vm.loadFailure;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfile)),
      body: vm.loading
          ? Center(
              child: CircularProgressIndicator(semanticsLabel: l10n.loading),
            )
          : loadFailure != null
          ? ErrorView(failure: loadFailure, onRetry: vm.load)
          : const _ProfileForm(),
    );
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<ProfileEditViewModel>();
    final languageCode = Localizations.localeOf(context).languageCode;
    final errorColor = Theme.of(context).colorScheme.error;
    final saveFailure = vm.saveFailure;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            initialValue: vm.displayName,
            decoration: InputDecoration(
              labelText: l10n.displayNameLabel,
              errorText: vm.nameError ? l10n.displayNameRequired : null,
            ),
            onChanged: (value) => vm.displayName = value,
          ),
          const SizedBox(height: AppSpacing.space4),
          TextFormField(
            initialValue: vm.bio,
            minLines: 2,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: l10n.bioLabel,
              helperText: vm.bioTooLong
                  ? null
                  : l10n.bioRemaining(vm.bioRemaining),
              errorText: vm.bioTooLong ? l10n.bioOver(-vm.bioRemaining) : null,
            ),
            onChanged: (value) => vm.bio = value,
          ),
          const SizedBox(height: AppSpacing.space4),
          DropdownButtonFormField<int?>(
            initialValue: vm.cityId,
            decoration: InputDecoration(labelText: l10n.cityLabel),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.cityNone)),
              for (final city in vm.cities)
                DropdownMenuItem(
                  value: city.id,
                  child: Text(city.label(languageCode)),
                ),
            ],
            onChanged: (value) => vm.cityId = value,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            l10n.contactLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          RadioGroup<ContactLinkType?>(
            groupValue: vm.contactType,
            onChanged: (value) => vm.contactType = value,
            child: Column(
              children: [
                RadioListTile<ContactLinkType?>(
                  value: null,
                  title: Text(l10n.contactNone),
                ),
                RadioListTile<ContactLinkType?>(
                  value: ContactLinkType.email,
                  title: Text(l10n.contactEmail),
                ),
                RadioListTile<ContactLinkType?>(
                  value: ContactLinkType.linkedin,
                  title: Text(l10n.contactLinkedin),
                ),
              ],
            ),
          ),
          if (vm.contactType != null) ...[
            TextFormField(
              key: ValueKey(vm.contactType),
              initialValue: vm.contactValue,
              keyboardType: vm.contactType == ContactLinkType.email
                  ? TextInputType.emailAddress
                  : TextInputType.url,
              decoration: InputDecoration(
                labelText: vm.contactType == ContactLinkType.email
                    ? l10n.contactEmailLabel
                    : l10n.contactLinkedinLabel,
                errorText: vm.contactError ? l10n.contactInvalid : null,
              ),
              onChanged: (value) => vm.contactValue = value,
            ),
            SwitchListTile(
              value: vm.contactVisible,
              title: Text(l10n.contactVisibleLabel),
              onChanged: (value) => vm.contactVisible = value,
            ),
          ],
          if (saveFailure != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Semantics(
              liveRegion: true,
              child: Text(
                failureMessage(l10n, saveFailure),
                style: TextStyle(color: errorColor),
              ),
            ),
          ],
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
