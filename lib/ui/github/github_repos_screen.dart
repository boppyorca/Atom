import 'package:flutter/material.dart';
import 'package:harness_app/data/repositories/auth_repository.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';
import 'package:harness_app/ui/core/widgets/busy_button.dart';
import 'package:harness_app/ui/core/widgets/error_view.dart';
import 'package:harness_app/ui/github/github_repos_view_model.dart';
import 'package:provider/provider.dart';

class GithubReposScreen extends StatefulWidget {
  const GithubReposScreen({super.key});

  @override
  State<GithubReposScreen> createState() => _GithubReposScreenState();
}

class _GithubReposScreenState extends State<GithubReposScreen>
    with WidgetsBindingObserver {
  AuthRepository? _auth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthRepository>();
    if (!identical(auth, _auth)) {
      _auth?.removeListener(_reloadAfterLogin);
      _auth = auth;
      auth.addListener(_reloadAfterLogin);
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_reloadAfterLogin);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _reloadAfterLogin() {
    if (!mounted) return;
    context.read<GithubReposViewModel>().load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<GithubReposViewModel>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<GithubReposViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.githubReposTitle)),
      body: _body(context, l10n, vm),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    GithubReposViewModel vm,
  ) {
    if (vm.loading && vm.repos.isEmpty && vm.failure == null) {
      return Center(child: Text(l10n.loading));
    }
    if (vm.failure is NetworkFailure && vm.repos.isEmpty) {
      return ErrorView(failure: vm.failure!, onRetry: vm.load);
    }
    if (!vm.connected) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text(l10n.githubPublicOnly),
          const SizedBox(height: AppSpacing.space4),
          BusyButton(
            label: l10n.githubConnect,
            busy: vm.running,
            onPressed: vm.connect,
          ),
          if (vm.failure != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              l10n.genericError,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Text(l10n.githubPublicOnly),
        const SizedBox(height: AppSpacing.space2),
        Text(l10n.githubSelectedCount(vm.selectedCount)),
        if (vm.failure is ValidationFailure) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(switch ((vm.failure! as ValidationFailure).code) {
            'github_rate_limited' => l10n.githubRateLimited,
            'github_not_found' => l10n.githubNotFound,
            _ => l10n.githubTooMany,
          }, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        for (final repo in vm.repos)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: repo.selected,
            title: Text(repo.name),
            subtitle: repo.isFork ? Text(l10n.githubFork) : null,
            onChanged: (_) => vm.toggle(repo),
          ),
        const SizedBox(height: AppSpacing.space4),
        BusyButton(
          label: l10n.githubSave,
          busy: vm.running,
          onPressed: vm.save,
        ),
        const SizedBox(height: AppSpacing.space2),
        OutlinedButton(
          onPressed: vm.running ? null : vm.disconnect,
          child: Text(l10n.githubDisconnect),
        ),
      ],
    );
  }
}
