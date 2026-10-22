import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:harness_app/domain/models/profile.dart';
import 'package:harness_app/main.dart';
import 'package:harness_app/routing/router.dart';
import 'package:harness_app/routing/routes.dart';
import 'package:harness_app/ui/core/app_failure.dart';
import 'package:harness_app/ui/core/result.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_profile_repository.dart';

void main() {
  Future<GoRouter> pumpApp(
    WidgetTester tester,
    FakeProfileRepository profiles, {
    bool settle = true,
  }) async {
    final auth = FakeAuthRepository()..signedIn = true;
    final router = createRouter(auth, profiles);
    await tester.pumpWidget(
      AtomApp(
        authRepository: auth,
        profileRepository: profiles,
        router: router,
        locale: const Locale('vi'),
      ),
    );
    if (settle) await tester.pumpAndSettle();
    return router;
  }

  group('S-03', () {
    testWidgets('shows a loading indicator while the profile loads', (
      tester,
    ) async {
      final profiles = FakeProfileRepository()..loadGate = Completer<void>();
      await pumpApp(tester, profiles, settle: false);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      profiles.loadGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Minh'), findsOneWidget);
    });

    testWidgets('shows name, city, bio and contact', (tester) async {
      final profiles = FakeProfileRepository()
        ..profile = const Profile(
          id: 'me',
          displayName: 'Minh',
          bio: 'Flutter dev',
          cityId: 2,
          contactType: ContactLinkType.email,
          contactValue: 'minh@example.com',
        );
      await pumpApp(tester, profiles);

      expect(find.text('Minh'), findsOneWidget);
      expect(find.text('TP. Hồ Chí Minh'), findsOneWidget);
      expect(find.text('Flutter dev'), findsOneWidget);
      expect(find.text('minh@example.com'), findsOneWidget);
    });

    testWidgets('offline shows no connection and retry recovers', (
      tester,
    ) async {
      final profiles = FakeProfileRepository()
        ..loadError = const Error(NetworkFailure());
      await pumpApp(tester, profiles);

      expect(find.text('Không có kết nối'), findsOneWidget);

      profiles.loadError = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Minh'), findsOneWidget);
    });

    testWidgets('server error shows a generic error', (tester) async {
      final profiles = FakeProfileRepository()
        ..loadError = const Error(ServerFailure());
      await pumpApp(tester, profiles);

      expect(find.text('Có lỗi, thử lại'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });

  group('S-04', () {
    Future<GoRouter> openEdit(
      WidgetTester tester,
      FakeProfileRepository profiles,
    ) async {
      final router = await pumpApp(tester, profiles);
      await tester.tap(find.byTooltip('Sửa hồ sơ'));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('edit, save, and S-03 shows the new values', (tester) async {
      final profiles = FakeProfileRepository();
      final router = await openEdit(tester, profiles);
      expect(router.state.uri.path, Routes.profileEdit);

      await tester.enterText(find.widgetWithText(TextField, 'Minh'), 'Lan');
      await tester.enterText(
        find.widgetWithText(TextField, 'Giới thiệu'),
        'React dev',
      );
      await tester.tap(find.text('Chưa chọn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hà Nội').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('LinkedIn'));
      await tester.tap(find.text('LinkedIn'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Link LinkedIn'),
        'https://www.linkedin.com/in/lan',
      );
      await tester.ensureVisible(find.text('Lưu'));
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, Routes.profile);
      expect(find.text('Lan'), findsOneWidget);
      expect(find.text('React dev'), findsOneWidget);
      expect(find.text('Hà Nội'), findsOneWidget);
      expect(find.text('https://www.linkedin.com/in/lan'), findsOneWidget);
    });

    testWidgets('bio shows remaining characters and blocks over 300', (
      tester,
    ) async {
      final profiles = FakeProfileRepository();
      await openEdit(tester, profiles);
      final bio = find.widgetWithText(TextField, 'Giới thiệu');

      await tester.enterText(bio, 'a' * 55);
      await tester.pump();
      expect(find.text('còn 245 ký tự'), findsOneWidget);

      await tester.enterText(bio, 'a' * 301);
      await tester.pump();
      expect(find.text('Quá 1 ký tự'), findsOneWidget);

      await tester.ensureVisible(find.text('Lưu'));
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(profiles.saveCount, 0);
    });

    testWidgets('offline save keeps typed data and shows no connection', (
      tester,
    ) async {
      final profiles = FakeProfileRepository()
        ..saveError = const Error(NetworkFailure());
      final router = await openEdit(tester, profiles);

      await tester.enterText(
        find.widgetWithText(TextField, 'Giới thiệu'),
        'Typed offline',
      );
      await tester.ensureVisible(find.text('Lưu'));
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, Routes.profileEdit);
      expect(find.text('Không có kết nối'), findsOneWidget);
      expect(find.text('Typed offline'), findsOneWidget);
    });

    testWidgets('empty name shows an error on the field', (tester) async {
      final profiles = FakeProfileRepository();
      await openEdit(tester, profiles);

      await tester.enterText(find.widgetWithText(TextField, 'Minh'), ' ');
      await tester.ensureVisible(find.text('Lưu'));
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(find.text('Nhập tên hiển thị (tối đa 60 ký tự)'), findsOneWidget);
      expect(profiles.saveCount, 0);
    });

    testWidgets('loading and offline load states', (tester) async {
      final profiles = FakeProfileRepository();
      final router = await pumpApp(tester, profiles);
      profiles
        ..loadGate = Completer<void>()
        ..loadError = const Error(NetworkFailure());
      unawaited(router.push(Routes.profileEdit));
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      profiles.loadGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Không có kết nối'), findsOneWidget);

      profiles.loadError = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Minh'), findsOneWidget);
    });
  });
}
