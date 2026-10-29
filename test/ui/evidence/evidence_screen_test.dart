import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/main.dart';
import 'package:harness_app/routing/router.dart';
import 'package:harness_app/routing/routes.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_profile_repository.dart';

void main() {
  testWidgets('S-07 shows an empty state, then a saved link', (tester) async {
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
    router.push(Routes.evidence);
    await tester.pumpAndSettle();

    expect(find.text('Chưa có link'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).at(0),
      'https://example.com/a',
    );
    await tester.enterText(find.byType(TextField).at(1), 'Ghi chú');
    await tester.tap(find.text('Thêm link'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Ghi chú'), findsOneWidget);
    expect(find.text('Chưa có link'), findsNothing);
  });
}
