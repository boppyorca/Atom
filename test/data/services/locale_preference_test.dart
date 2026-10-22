import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/data/services/locale_preference.dart';

void main() {
  test(
    'first launch follows the device, and falls back to Vietnamese',
    () async {
      final english = LocalePreference(
        MemoryPreferenceStore(),
        deviceLocale: const Locale('en'),
      );
      await english.load();
      expect(english.locale, const Locale('en'));

      final french = LocalePreference(
        MemoryPreferenceStore(),
        deviceLocale: const Locale('fr'),
      );
      await french.load();
      expect(french.locale, const Locale('vi'));
    },
  );

  test('the chosen language is remembered', () async {
    final store = MemoryPreferenceStore();
    final preference = LocalePreference(
      store,
      deviceLocale: const Locale('en'),
    );
    await preference.load();
    await preference.choose(const Locale('vi'));

    final reopened = LocalePreference(store, deviceLocale: const Locale('en'));
    await reopened.load();
    expect(reopened.locale, const Locale('vi'));
  });
}
