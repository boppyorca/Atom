import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vi and en arb files have the same message keys', () {
    final en = _keys(File('lib/l10n/app_en.arb'));
    final vi = _keys(File('lib/l10n/app_vi.arb'));
    expect(vi, en);
  });
}

Set<String> _keys(File file) {
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return json.keys.where((key) => !key.startsWith('@')).toSet();
}
