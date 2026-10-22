import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/main.dart';
import 'package:harness_app/routing/router.dart';
import 'package:harness_app/routing/routes.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  testWidgets('unsigned user is sent to sign-in', (tester) async {
    final auth = FakeAuthRepository();
    final router = createRouter(auth);
    await tester.pumpWidget(
      AtomApp(authRepository: auth, router: router, locale: const Locale('vi')),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.path, Routes.signIn);
    expect(find.text('Gửi mã đăng nhập'), findsOneWidget);
  });

  testWidgets('signed-in user on sign-in is sent to profile', (tester) async {
    final auth = FakeAuthRepository()..signedIn = true;
    final router = createRouter(auth);
    await tester.pumpWidget(
      AtomApp(authRepository: auth, router: router, locale: const Locale('vi')),
    );
    await tester.pumpAndSettle();
    router.go(Routes.signIn);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, Routes.profile);
    expect(find.text('Hồ sơ của bạn sẽ hiện ở đây.'), findsOneWidget);
  });

  testWidgets('sign-out returns to sign-in', (tester) async {
    final auth = FakeAuthRepository()..signedIn = true;
    final router = createRouter(auth);
    await tester.pumpWidget(
      AtomApp(authRepository: auth, router: router, locale: const Locale('vi')),
    );
    await tester.pumpAndSettle();

    auth.signedIn = false;
    auth.notifyListeners();
    await tester.pumpAndSettle();

    expect(router.state.uri.path, Routes.signIn);
  });
}
