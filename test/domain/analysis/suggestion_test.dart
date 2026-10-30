import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/domain/analysis/suggestion.dart';

void main() {
  test('a cut-short scan is a flag, not a commit total', () {
    expect(
      historyWasCutShort({
        'minh/app': {'listed_commit_count': 100, 'scan_truncated': false},
      }),
      isFalse,
    );
    expect(
      historyWasCutShort({
        'minh/app': {'listed_commit_count': 4, 'scan_truncated': true},
      }),
      isTrue,
    );
  });
}
