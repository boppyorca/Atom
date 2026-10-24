import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/routing/routes.dart';
import 'package:harness_app/ui/consent/consent_view_model.dart';
import 'package:harness_app/ui/core/theme/app_colors.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:harness_app/ui/core/widgets/error_view.dart';
import 'package:harness_app/ui/profile/profile_view_model.dart';
import 'package:provider/provider.dart';

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final block = AppColors.textSecondary.withValues(alpha: 0.18);
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: block,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
    );
    return Semantics(
      key: const Key('profile-skeleton'),
      label: AppLocalizations.of(context).loading,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          bar(160, 28),
          const SizedBox(height: AppSpacing.space2),
          bar(110, 16),
          const SizedBox(height: AppSpacing.space4),
          bar(double.infinity, 16),
          const SizedBox(height: AppSpacing.space2),
          bar(220, 16),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<ProfileViewModel>();
    final consent = context.watch<ConsentViewModel>();
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
        (true, _, _) => const _ProfileSkeleton(),
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
            const SizedBox(height: AppSpacing.space4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.findSkills),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final destination = consent.analysisDestination;
                context.push(destination ?? Routes.findSkills);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.compareJobTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.compareJob),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.skillsTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.skills),
            ),
          ],
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
