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
    return client.from('profiles').select(columns).eq('id', _userId).single();
  }

  Future<void> updateOwnProfile(Map<String, dynamic> values) {
    return client.from('profiles').update(values).eq('id', _userId);
  }

  Future<List<Map<String, dynamic>>> selectCities() {
    return client
        .from('cities')
        .select('id, code, label_vi, label_en')
        .order('id');
  }

  Future<List<Map<String, dynamic>>> selectOwnSkills() {
    return client
        .from('skills')
        .select('id, name, confidence')
        .eq('profile_id', _userId)
        .order('created_at');
  }

  Future<Map<String, dynamic>> insertOwnSkill(String name) {
    return client
        .from('skills')
        .insert({'profile_id': _userId, 'name': name})
        .select('id, name, confidence')
        .single();
  }

  Future<void> deleteOwnSkill(String id) {
    return client
        .from('skills')
        .delete()
        .eq('id', id)
        .eq('profile_id', _userId);
  }
}
