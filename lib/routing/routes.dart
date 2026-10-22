abstract final class Routes {
  static const signIn = '/sign-in';
  static const signInOtp = '/sign-in/otp';
  static const profile = '/profile';
  static const discover = '/discover';
  static const salary = '/salary';
  static const settings = '/settings';

  static String signInOtpWithEmail(String email) =>
      Uri(path: signInOtp, queryParameters: {'email': email}).toString();
}
