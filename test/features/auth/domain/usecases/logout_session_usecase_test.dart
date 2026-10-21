import 'package:animal_record/features/auth/domain/services/session_state_cleaner.dart';
import 'package:animal_record/features/auth/domain/services/social_session_service.dart';
import 'package:animal_record/features/auth/domain/usecases/logout_session_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/logout_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionStateCleaner extends Mock implements SessionStateCleaner {}

class MockSocialSessionService extends Mock implements SocialSessionService {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

void main() {
  test('limpia estado, sesiones sociales y tokens en ese orden', () async {
    final stateCleaner = MockSessionStateCleaner();
    final socialSessionService = MockSocialSessionService();
    final logoutUseCase = MockLogoutUseCase();
    final useCase = LogoutSessionUseCase(
      sessionStateCleaner: stateCleaner,
      socialSessionService: socialSessionService,
      logoutUseCase: logoutUseCase,
    );
    when(() => stateCleaner.clear()).thenAnswer((_) async {});
    when(() => socialSessionService.signOut()).thenAnswer((_) async {});
    when(() => logoutUseCase()).thenAnswer((_) async => const Right(null));

    await useCase();

    verifyInOrder([
      () => stateCleaner.clear(),
      () => socialSessionService.signOut(),
      () => logoutUseCase(),
    ]);
  });
}
