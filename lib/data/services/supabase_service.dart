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
}
