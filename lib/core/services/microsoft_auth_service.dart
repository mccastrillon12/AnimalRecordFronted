import 'package:msal_auth/msal_auth.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class MicrosoftAuthService {
  final Logger logger;
  SingleAccountPca? _pca;

  static const String _clientId = '91b57fa9-3b6e-450a-beb8-86303c7b6cd0';
  static const String _authority = "https://login.microsoftonline.com/common";
  static const String _redirectUriAndroid =
      "msauth://com.animalRecord.animal_record/2ebQI5bRT%2FNwWP926aXx82ZpYvA%3D";
  static const List<String> _scopes = [
    'User.Read',
    'email',
  ];

  MicrosoftAuthService({required this.logger});

  bool get isInitialized => _pca != null;

  Future<void> initialize() async {
    try {
      _pca = await SingleAccountPca.create(
        clientId: _clientId,
        androidConfig: AndroidConfig(
          configFilePath: 'assets/msal_config.json',
          redirectUri: _redirectUriAndroid,
        ),
        appleConfig: AppleConfig(authority: _authority),
      );
      logger.i("Microsoft Auth Service Initialized");
    } catch (e) {
      logger.e("Failed to initialize Microsoft Auth Service: $e");
    }
  }

  Future<String?> signIn() async {
    try {
      if (_pca == null) {
        await initialize();
      }

      if (_pca == null) {
        throw Exception("MSAL not initialized");
      }

      await signOut();

      final result = await _pca!.acquireToken(scopes: _scopes);

      logger.i("Microsoft Sign In Successful. Token received.");
      return result.accessToken;
    } on MsalException catch (e) {
      logger.e("MSAL Exception: ${e.message}");
      throw Exception("Error de Microsoft: ${e.message}");
    } on PlatformException catch (e) {
      logger.e("Platform Exception during MSAL Sign In: ${e.message}");
      throw Exception("Error de Plataforma: ${e.message}");
    } catch (e) {
      logger.e("Unexpected error during Microsoft Sign In: $e");
      throw Exception("Error inesperado al iniciar sesión con Microsoft");
    }
  }

  Future<void> signOut() async {
    try {
      if (_pca == null) {
        await initialize();
      }
      if (_pca != null) {
        await _pca!.signOut();
        logger.i("Microsoft Sign Out Successful");
      }
    } catch (e) {
      logger.e("Error during Microsoft Sign Out: $e");
    }
  }
}
