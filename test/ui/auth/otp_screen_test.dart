import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/l10n/app_localizations.dart';
import 'package:harness_app/ui/auth/otp_screen.dart';
import 'package:harness_app/ui/auth/otp_view_model.dart';
import 'package:provider/provider.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  testWidgets('the locked resend button still has a readable label', (
    tester,
  ) async {
    final vm = OtpViewModel(FakeAuthRepository(), email: 'minh@example.com');
    await tester.pumpWidget(
      ChangeNotifierProvider<OtpViewModel>.value(
        value: vm,
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OtpScreen(),
        ),
      ),
    );

    expect(find.text('Gửi lại mã (sau 60 giây)'), findsOneWidget);
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });
}
