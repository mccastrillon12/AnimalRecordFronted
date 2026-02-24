import 'dart:async';
import 'package:animal_record/features/auth/domain/usecases/validate_password_token_usecase.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> initDeepLinks(GlobalKey<NavigatorState> navigatorKey) async {
    // Check initial link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _waitForNavigatorAndHandle(initialLink, navigatorKey);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Listen to incoming links
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _waitForNavigatorAndHandle(uri, navigatorKey),
      onError: (err) => debugPrint('Deep Link Error: $err'),
    );
  }

  ValidatePasswordTokenUseCase? _validatePasswordTokenUseCase;

  void setValidatePasswordTokenUseCase(ValidatePasswordTokenUseCase useCase) {
    _validatePasswordTokenUseCase = useCase;
  }

  Uri? _lastUri;
  bool _isHandlingLink = false;
  bool get isHandlingDeepLink => _isHandlingLink;

  void _waitForNavigatorAndHandle(
    Uri uri,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    if (_isHandlingLink) return;
    _isHandlingLink = true;

    // Check against last handled URI to prevent double processing
    if (uri == _lastUri) {
      _isHandlingLink = false;
      return;
    }
    _lastUri = uri;

    debugPrint('Received Deep Link: $uri');

    // Wait for navigatorKey.currentState to be available
    int retries = 0;
    while (navigatorKey.currentState == null && retries < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      retries++;
    }

    _processLink(uri, navigatorKey);
  }

  void _processLink(Uri uri, GlobalKey<NavigatorState> navigatorKey) async {
    // Wait until SplashScreen has finished its navigation
    bool isSplashTop() {
      bool isSplash = false;
      navigatorKey.currentState?.popUntil((route) {
        isSplash = route.settings.name == '/';
        return true; // Stop immediately, we only want to check the top route
      });
      return isSplash;
    }

    int splashRetries = 0;
    while (isSplashTop() && splashRetries < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      splashRetries++;
    }

    // Handle password and PIN reset
    // Format: https://animalrecord.app/reset-password?token=...
    // Format: https://animalrecord.app/reset-pin?token=...&type=pin
    final isPasswordReset = uri.path == '/reset-password';
    final isPinReset =
        uri.path == '/reset-pin' || uri.queryParameters['type'] == 'pin';

    if (isPasswordReset || isPinReset) {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        final identifier =
            uri.queryParameters['identifier'] ?? uri.queryParameters['email'];

        if (navigatorKey.currentState != null) {
          if (isPinReset) {
            // Bypass pre-validation for PIN tokens since the backend endpoint
            // /auth/validate-password-token might reject PIN tokens.
            // Validation will happen on submission instead.
            navigatorKey.currentState?.pushNamed(
              '/reset-pin',
              arguments: {'token': token, 'identifier': identifier},
            );
            return;
          }

          if (_validatePasswordTokenUseCase != null) {
            final context = navigatorKey.currentState!.context;

            // Show transparent loading dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.black54,
              builder: (ctx) =>
                  const Center(child: CircularProgressIndicator()),
            );

            // Validate token
            // We wait a bit to ensure the dialog is shown and to give a smooth experience
            await Future.delayed(const Duration(milliseconds: 250));

            final result = await _validatePasswordTokenUseCase!(
              identifier ?? '',
              token,
            );

            // Dismiss loading dialog
            if (navigatorKey.currentState?.canPop() == true) {
              navigatorKey.currentState?.pop();
            }

            result.fold(
              (failure) {
                // On failure (network or invalid), go to expired
                navigatorKey.currentState?.pushNamed('/link-expired');
              },
              (isValid) {
                if (isValid) {
                  final routeName = isPinReset
                      ? '/reset-pin'
                      : '/reset-password';
                  navigatorKey.currentState?.pushNamed(
                    routeName,
                    arguments: {'token': token, 'identifier': identifier},
                  );
                } else {
                  navigatorKey.currentState?.pushNamed('/link-expired');
                }
              },
            );
          }
        }
      }
    }

    // Reset handling flag after a delay to allow re-clicking if needed (debounce)
    Future.delayed(const Duration(seconds: 2), () {
      _isHandlingLink = false;
      // We clear _lastUri to allow clicking the same link again after the delay
      // if the user went back and clicked it again.
      _lastUri = null;
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
