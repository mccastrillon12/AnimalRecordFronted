import 'package:animal_record/core/services/app_logger.dart';
import 'package:animal_record/core/services/microsoft_auth_service.dart';
import 'package:animal_record/features/auth/domain/services/social_session_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SocialSessionServiceImpl implements SocialSessionService {
  final GoogleSignIn googleSignIn;
  final MicrosoftAuthService microsoftAuthService;
  final AppLogger logger;

  const SocialSessionServiceImpl({
    required this.googleSignIn,
    required this.microsoftAuthService,
    required this.logger,
  });

  @override
  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
    } catch (e) {
      logger.warning('Error al desconectar GoogleSignIn: $e');
    }

    try {
      await microsoftAuthService.signOut();
    } catch (_) {
      // Social logout is best-effort and must not block local logout.
    }
  }
}
