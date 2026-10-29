import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/config/env.dart';

void main() {
  test('the share link uses the public site and the profile id', () {
    expect(
      Env.publicProfileUrl('11111111-1111-1111-1111-111111111111'),
      'http://127.0.0.1:3000/p/?id=11111111-1111-1111-1111-111111111111',
    );
  });
}
