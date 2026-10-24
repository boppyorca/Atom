import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/main.dart';
import 'package:harness_app/routing/router.dart';
import 'package:harness_app/routing/routes.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_profile_repository.dart';

void main() {
  testWidgets('comparing a job lists a missing skill', (tester) async {
    final auth = FakeAuthRepository()..signedIn = true;
    final profiles = FakeProfileRepository();
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
    router.push(Routes.compareJob);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Cần Flutter và Docker');
    await tester.tap(find.text('So'));
    await tester.pumpAndSettle();

    expect(find.text('Tin cần, hồ sơ chưa có'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('Docker'), findsOneWidget);
  });

  testWidgets('find skills asks for a repository first', (tester) async {
    final auth = FakeAuthRepository()..signedIn = true;
    final profiles = FakeProfileRepository();
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
    router.push(Routes.findSkills);
    await tester.pumpAndSettle();

    expect(find.text('Hãy chọn repo trước'), findsOneWidget);
  });
}
