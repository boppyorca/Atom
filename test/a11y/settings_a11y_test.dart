import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/data/services/locale_preference.dart';
import 'package:harness_app/main.dart';
import 'package:harness_app/routing/router.dart';
import 'package:harness_app/routing/routes.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_profile_repository.dart';

void main() {
  testWidgets('S-16 meets accessibility guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    final auth = FakeAuthRepository()..signedIn = true;
    final router = createRouter(auth, FakeProfileRepository());
    await tester.pumpWidget(
      AtomApp(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
        localePreference: LocalePreference(MemoryPreferenceStore()),
        router: router,
        locale: const Locale('vi'),
      ),
    );
    await tester.pumpAndSettle();
    router.go(Routes.settings);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('S-18 meets accessibility guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    final auth = FakeAuthRepository()..signedIn = true;
    final router = createRouter(auth, FakeProfileRepository());
    await tester.pumpWidget(
      AtomApp(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
        localePreference: LocalePreference(MemoryPreferenceStore()),
        router: router,
        locale: const Locale('vi'),
      ),
    );
    await tester.pumpAndSettle();
    router.push(Routes.deleteAccount);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
