import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/data/services/locale_preference.dart';
import 'package:harness_app/main.dart';
import 'package:harness_app/routing/router.dart';
import 'package:harness_app/routing/routes.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_profile_repository.dart';

void main() {
  testWidgets('choosing a language updates the visible text immediately', (
    tester,
  ) async {
    final preference = LocalePreference(MemoryPreferenceStore());
    await preference.load();
    final auth = FakeAuthRepository()..signedIn = true;
    final router = createRouter(auth, FakeProfileRepository());
    await tester.pumpWidget(
      AtomApp(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
        localePreference: preference,
        router: router,
      ),
    );
    await tester.pumpAndSettle();
    router.go(Routes.settings);
    await tester.pumpAndSettle();

    expect(find.text('Cài đặt'), findsWidgets);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Sign out'), findsOneWidget);
  });
}
