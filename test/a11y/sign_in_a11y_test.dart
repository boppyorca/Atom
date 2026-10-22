import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/main.dart';
import 'package:harness_app/routing/router.dart';
import 'package:harness_app/routing/routes.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_profile_repository.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, {required String location}) async {
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
    router.go(location);
    await tester.pumpAndSettle();
  }

  testWidgets('S-01 meets accessibility guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpAt(tester, location: Routes.signIn);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('S-02 meets accessibility guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpAt(
      tester,
      location: Routes.signInOtpWithEmail('minh@example.com'),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
