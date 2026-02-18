import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:logger/logger.dart';
import 'dart:io';

class AppleAuthService {
  final Logger logger;

  AppleAuthService({required this.logger});

  Future<AuthorizationCredentialAppleID?> signIn() async {
    try {
      if (!Platform.isIOS) {
        logger.w("Apple Sign In is only supported on iOS");
        return null;
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      logger.i("Apple Sign In Successful. Token received.");
      return credential;
    } catch (e) {
      logger.e("Error during Apple Sign In: $e");
      return null;
    }
  }
}
