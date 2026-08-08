import 'package:animal_record/core/services/app_logger.dart';
import 'package:animal_record/core/services/microsoft_auth_service.dart';
import 'package:animal_record/features/auth/data/services/social_session_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockMicrosoftAuthService extends Mock implements MicrosoftAuthService {}

class MockAppLogger extends Mock implements AppLogger {}

void main() {
  test('continúa con Microsoft si Google falla', () async {
    final googleSignIn = MockGoogleSignIn();
    final microsoftAuthService = MockMicrosoftAuthService();
    final logger = MockAppLogger();
    final service = SocialSessionServiceImpl(
      googleSignIn: googleSignIn,
      microsoftAuthService: microsoftAuthService,
      logger: logger,
    );
    when(() => googleSignIn.signOut()).thenThrow(Exception('Google error'));
    when(() => microsoftAuthService.signOut()).thenAnswer((_) async {});

    await service.signOut();

    verify(
      () => logger.warning(any(that: contains('Google error'))),
    ).called(1);
    verify(() => microsoftAuthService.signOut()).called(1);
  });
}
