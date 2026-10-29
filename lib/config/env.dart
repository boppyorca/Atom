class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const publicProfileBaseUrl = String.fromEnvironment(
    'PUBLIC_PROFILE_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );

  static String publicProfileUrl(String profileId) {
    final base = publicProfileBaseUrl.endsWith('/')
        ? publicProfileBaseUrl.substring(0, publicProfileBaseUrl.length - 1)
        : publicProfileBaseUrl;
    return '$base/p/?id=$profileId';
  }
}
