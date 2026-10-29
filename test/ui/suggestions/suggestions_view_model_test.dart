import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/domain/analysis/suggestion.dart';
import 'package:harness_app/ui/suggestions/suggestions_view_model.dart';

import '../../fakes/fake_profile_repository.dart';

void main() {
  test('a running job past its deadline shows timed out', () async {
    final now = DateTime.utc(2026, 10, 25, 12);
    final repo = FakeProfileRepository()
      ..analysisJob = AnalysisJob(
        id: 'job-1',
        status: 'running',
        deadline: now.subtract(const Duration(seconds: 1)),
      );
    final vm = SuggestionsViewModel(repo, now: () => now);

    await vm.load();
    expect(vm.jobStatus, 'timed_out');
  });

  test('a finished unseen job shows the new-result mark', () async {
    final repo = FakeProfileRepository()
      ..analysisJob = AnalysisJob(
        id: 'job-1',
        status: 'succeeded',
        deadline: DateTime.utc(2026, 10, 25, 13),
      );
    final vm = SuggestionsViewModel(repo);

    await vm.load();
    expect(vm.unseen, isTrue);

    await vm.markSeen();
    expect(vm.unseen, isFalse);
  });
}
