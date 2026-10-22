import 'package:harness_app/config/request_timeout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService(this.client);

  final SupabaseClient client;

  Session? get currentSession => client.auth.currentSession;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<void> signInWithOtp({required String email}) {
    return client.auth.signInWithOtp(email: email);
  }

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  Future<void> signOut() => client.auth.signOut();

  String get _userId => client.auth.currentUser!.id;

  Future<Map<String, dynamic>> selectOwnProfile(String columns) {
    return client
        .from('profiles')
        .select(columns)
        .eq('id', _userId)
        .single()
        .timeout(requestTimeout);
  }

  Future<void> updateOwnProfile(Map<String, dynamic> values) {
    return client
        .from('profiles')
        .update(values)
        .eq('id', _userId)
        .timeout(requestTimeout);
  }

  Future<List<Map<String, dynamic>>> selectCities() {
    return client
        .from('cities')
        .select('id, code, label_vi, label_en')
        .order('id')
        .timeout(requestTimeout);
  }
}
