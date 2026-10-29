import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/main.dart';
import 'package:harness_app/routing/router.dart';
import 'package:harness_app/routing/routes.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_profile_repository.dart';

void main() {
  testWidgets('S-09 meets accessibility guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    final auth = FakeAuthRepository()..signedIn = true;
    final profile = FakeProfileRepository();
    final router = createRouter(auth, profile);
    await tester.pumpWidget(
      AtomApp(
        authRepository: auth,
        profileRepository: profile,
        router: router,
        locale: const Locale('vi'),
      ),
    );
    await tester.pumpAndSettle();
    router.push(Routes.suggestions);
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
