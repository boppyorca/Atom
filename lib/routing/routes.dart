abstract final class Routes {
  static const signIn = '/sign-in';
  static const signInOtp = '/sign-in/otp';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const skills = '/profile/skills';
  static const githubRepos = '/profile/github';
  static const suggestions = '/profile/suggestions';
  static const evidence = '/profile/evidence';
  static const gap = '/profile/gap';
  static const feed = '/profile/feed';
  static const chat = '/profile/chat';
  static const discover = '/discover';
  static const salary = '/salary';
  static const salaryEntry = '/salary/entry';
  static const settings = '/settings';
  static const notices = '/settings/notices';
  static const deleteAccount = '/settings/delete';
  static const blockedPeople = '/settings/blocked';
  static const reportProfile = '/settings/report';
  static const aiConsent = '/ai-consent';

  static String signInOtpWithEmail(String email) =>
      Uri(path: signInOtp, queryParameters: {'email': email}).toString();
}
