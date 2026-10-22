import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

const localePreferenceKey = 'locale';

abstract class PreferenceStore {
  String? read(String key);

  Future<void> write(String key, String value);
}

class MemoryPreferenceStore implements PreferenceStore {
  final _values = <String, String>{};

  @override
  String? read(String key) => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}

class SharedPreferencesStore implements PreferenceStore {
  SharedPreferencesStore(this._preferences);

  final SharedPreferences _preferences;

  @override
  String? read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}

class LocalePreference extends ChangeNotifier {
  LocalePreference(this._store, {this.deviceLocale = const Locale('vi')});

  final PreferenceStore _store;
  final Locale deviceLocale;
  Locale locale = const Locale('vi');

  Future<void> load() async {
    locale = _resolve(_store.read(localePreferenceKey));
    notifyListeners();
  }

  Future<void> choose(Locale value) async {
    await _store.write(localePreferenceKey, value.languageCode);
    locale = value;
    notifyListeners();
  }

  Locale _resolve(String? saved) {
    if (saved == 'vi' || saved == 'en') return Locale(saved!);
    if (deviceLocale.languageCode == 'en') return const Locale('en');
    return const Locale('vi');
  }
}
