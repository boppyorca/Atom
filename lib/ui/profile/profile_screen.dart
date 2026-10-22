import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/routing/routes.dart';
import 'package:harness_app/ui/core/theme/app_colors.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:harness_app/ui/core/widgets/error_view.dart';
import 'package:harness_app/ui/profile/profile_view_model.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<ProfileViewModel>();
    final profile = vm.profile;
    final failure = vm.failure;
    final textTheme = Theme.of(context).textTheme;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          if (profile != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.editProfile,
              onPressed: () async {
                final saved = await context.push<bool>(Routes.profileEdit);
                if (saved == true) await vm.load();
              },
            ),
        ],
      ),
      body: switch ((vm.loading, failure, profile)) {
        (true, _, _) => Center(
          child: CircularProgressIndicator(semanticsLabel: l10n.loading),
        ),
        (_, final failure?, _) => ErrorView(failure: failure, onRetry: vm.load),
        (_, _, final profile?) => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Text(profile.displayName, style: textTheme.headlineSmall),
            if (vm.city != null)
              Text(
                vm.city!.label(languageCode),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            if (profile.bio != null) ...[
              const SizedBox(height: AppSpacing.space4),
              Text(profile.bio!, style: textTheme.bodyLarge),
            ],
            if (profile.contactValue != null) ...[
              const SizedBox(height: AppSpacing.space4),
              Text(l10n.contactLabel, style: textTheme.titleMedium),
              Text(profile.contactValue!, style: textTheme.bodyLarge),
            ],
          ],
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
