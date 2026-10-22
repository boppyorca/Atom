import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/data/services/secure_session_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('persists, reads and removes the session', () async {
    final storage = SecureSessionStorage(storage: FlutterSecureStorage());

    await storage.initialize();
    expect(await storage.hasAccessToken(), isFalse);

    await storage.persistSession('session-json');
    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.accessToken(), 'session-json');

    await storage.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);
  });

  test('uses the supabase session key', () async {
    final storage = SecureSessionStorage(storage: FlutterSecureStorage());
    await storage.persistSession('session-json');

    const plugin = FlutterSecureStorage();
    expect(await plugin.read(key: supabasePersistSessionKey), 'session-json');
  });
}
