import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/main.dart';
import 'package:harness_app/routing/router.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_profile_repository.dart';

void main() {
  testWidgets('app builds the sign-in screen when unsigned', (tester) async {
    final profiles = FakeProfileRepository();
    final auth = FakeAuthRepository();
    await tester.pumpWidget(
      AtomApp(
        authRepository: auth,
        profileRepository: profiles,
        router: createRouter(auth, profiles),
        locale: const Locale('vi'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Atom'), findsOneWidget);
    expect(find.text('Gửi mã đăng nhập'), findsOneWidget);
  });
}
