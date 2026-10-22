import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/main.dart';
import 'package:harness_app/routing/router.dart';
import 'package:harness_app/routing/routes.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_profile_repository.dart';

void main() {
  testWidgets('S-05 shows an empty state, then a duplicate error', (
    tester,
  ) async {
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
    router.push(Routes.skills);
    await tester.pumpAndSettle();

    expect(find.text('Chưa có skill'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Flutter');
    await tester.tap(find.text('Thêm skill'));
    await tester.pumpAndSettle();
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('Tự khai'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'flutter');
    await tester.tap(find.text('Thêm skill'));
    await tester.pumpAndSettle();
    expect(find.text('Skill này đã có'), findsOneWidget);
  });

  testWidgets('S-05 shows an error when skills cannot be loaded', (
    tester,
  ) async {
    final auth = FakeAuthRepository()..signedIn = true;
    final profiles = FakeProfileRepository()
      ..loadError = const Error(NetworkFailure());
    final router = createRouter(auth, profiles);
    await tester.pumpWidget(
      AtomApp(
        authRepository: auth,
        profileRepository: profiles,
        router: router,
        locale: const Locale('vi'),
      ),
    );
    router.push(Routes.skills);
    await tester.pumpAndSettle();

    expect(find.text('Không có kết nối'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
