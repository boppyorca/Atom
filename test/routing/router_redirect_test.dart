import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/main.dart';
import 'package:harness_app/routing/router.dart';
import 'package:harness_app/routing/routes.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_profile_repository.dart';

void main() {
  testWidgets('unsigned user is sent to sign-in', (tester) async {
    final profiles = FakeProfileRepository();
    final auth = FakeAuthRepository();
    final router = createRouter(auth, profiles);
    await tester.pumpWidget(
      AtomApp(
        authRepository: auth,
        profileRepository: profiles,
        router: router,
        locale: const Locale('vi'),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.path, Routes.signIn);
    expect(find.text('Gửi mã đăng nhập'), findsOneWidget);
  });

  testWidgets('signed-in user on sign-in is sent to profile', (tester) async {
    final profiles = FakeProfileRepository();
    final auth = FakeAuthRepository()..signedIn = true;
    final router = createRouter(auth, profiles);
    await tester.pumpWidget(
      AtomApp(
        authRepository: auth,
        profileRepository: profiles,
        router: router,
        locale: const Locale('vi'),
      ),
    );
    await tester.pumpAndSettle();
    router.go(Routes.signIn);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, Routes.profile);
    expect(find.text('Minh'), findsOneWidget);
  });

  testWidgets('sign-out returns to sign-in', (tester) async {
    final profiles = FakeProfileRepository();
    final auth = FakeAuthRepository()..signedIn = true;
    final router = createRouter(auth, profiles);
    await tester.pumpWidget(
      AtomApp(
        authRepository: auth,
        profileRepository: profiles,
        router: router,
        locale: const Locale('vi'),
      ),
    );
    await tester.pumpAndSettle();

    auth.signedIn = false;
    auth.notifyListeners();
    await tester.pumpAndSettle();

    expect(router.state.uri.path, Routes.signIn);
  });
}
