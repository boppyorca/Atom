import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/main.dart';
import 'package:harness_app/routing/router.dart';
import 'package:harness_app/routing/routes.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_profile_repository.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, {required String location}) async {
    final auth = FakeAuthRepository()..signedIn = true;
    final profiles = FakeProfileRepository()
      ..profile = const Profile(
        id: 'me',
        displayName: 'Minh',
        bio: 'Flutter dev',
        cityId: 2,
        contactType: ContactLinkType.email,
        contactValue: 'minh@example.com',
      );
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
    if (location != Routes.profile) {
      router.push(location);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('S-03 meets accessibility guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpAt(tester, location: Routes.profile);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('S-04 meets accessibility guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpAt(tester, location: Routes.profileEdit);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
