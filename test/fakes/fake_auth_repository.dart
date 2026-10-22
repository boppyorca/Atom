import 'package:harness_app/data/repositories/auth_repository.dart';
import 'package:harness_app/ui/core/result.dart';

class FakeAuthRepository extends AuthRepository {
  bool signedIn = false;
  Result<void> requestResult = const Ok(null);
  Result<void> verifyResult = const Ok(null);
  Result<void> signOutResult = const Ok(null);
  int requestCount = 0;
  String? lastEmail;
  String? lastToken;

  @override
  bool get isSignedIn => signedIn;

  @override
  Future<Result<void>> requestEmailOtp(String email) async {
    requestCount += 1;
    lastEmail = email;
    return requestResult;
  }

  @override
  Future<Result<void>> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    lastEmail = email;
    lastToken = token;
    if (verifyResult is Ok<void>) {
      signedIn = true;
      notifyListeners();
    }
    return verifyResult;
  }

  @override
  Future<Result<void>> signOut() async {
    if (signOutResult is Ok<void>) {
      signedIn = false;
      notifyListeners();
    }
    return signOutResult;
  }

  void emitSignedIn() {
    signedIn = true;
    notifyListeners();
  }
}
