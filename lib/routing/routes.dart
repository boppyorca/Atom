abstract final class Routes {
  static const signIn = '/sign-in';
  static const signInOtp = '/sign-in/otp';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const skills = '/profile/skills';
  static const findSkills = '/profile/find-skills';
  static const compareJob = '/profile/compare-job';
  static const discover = '/discover';
  static const salary = '/salary';
  static const salaryEntry = '/salary/entry';
  static const settings = '/settings';
  static const aiConsent = '/ai-consent';

  static String signInOtpWithEmail(String email) =>
      Uri(path: signInOtp, queryParameters: {'email': email}).toString();
}
