import 'package:animal_record/features/auth/domain/services/session_state_cleaner.dart';
import 'package:animal_record/features/auth/domain/services/social_session_service.dart';
import 'package:animal_record/features/auth/domain/usecases/logout_usecase.dart';

class LogoutSessionUseCase {
  final SessionStateCleaner sessionStateCleaner;
  final SocialSessionService socialSessionService;
  final LogoutUseCase logoutUseCase;

  const LogoutSessionUseCase({
    required this.sessionStateCleaner,
    required this.socialSessionService,
    required this.logoutUseCase,
  });

  Future<void> call() async {
    await sessionStateCleaner.clear();
    await socialSessionService.signOut();
    await logoutUseCase();
  }
}
