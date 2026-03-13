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
    try {
      // FIX 1: getInitialLink() is the correct API for this version of app_links
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _waitForNavigatorAndHandle(initialLink, navigatorKey);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _waitForNavigatorAndHandle(uri, navigatorKey),
      onError: (err) => debugPrint('Deep Link Error: $err'),
    );
  }

  // Keep setValidatePasswordTokenUseCase for compatibility with main.dart
  // (no longer used inside the service but kept to avoid breaking main.dart)
  ValidatePasswordTokenUseCase? _validatePasswordTokenUseCase;

  void setValidatePasswordTokenUseCase(ValidatePasswordTokenUseCase useCase) {
    _validatePasswordTokenUseCase = useCase;
  }

  bool _isHandlingLink = false;
  bool get isHandlingDeepLink => _isHandlingLink;
  Uri? _processedUri;

  void _waitForNavigatorAndHandle(
    Uri uri,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    // FIX 2: mark as handling BEFORE any await so iOS doesn't timeout and open Safari
    if (_isHandlingLink) return;
    if (uri == _processedUri) return;
    _isHandlingLink = true;
    _processedUri = uri;

    debugPrint('Received Deep Link: $uri');

    int retries = 0;
    while (navigatorKey.currentState == null && retries < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      retries++;
    }

    _processLink(uri, navigatorKey);
  }

  void _processLink(Uri uri, GlobalKey<NavigatorState> navigatorKey) async {
    bool isSplashTop() {
      bool isSplash = false;
      navigatorKey.currentState?.popUntil((route) {
        isSplash = route.settings.name == '/';
        return true;
      });
      return isSplash;
    }

    int splashRetries = 0;
    while (isSplashTop() && splashRetries < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      splashRetries++;
    }

    final isPasswordReset = uri.path == '/reset-password';
    final isPinReset =
        uri.path == '/reset-pin' || uri.queryParameters['type'] == 'pin';

    if (isPasswordReset || isPinReset) {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        var identifier =
            uri.queryParameters['identifier'] ?? uri.queryParameters['email'];

        if (identifier != null) {
          identifier = identifier.replaceAll(' ', '+');
        }

        if (navigatorKey.currentState != null) {
          // FIX 3: Navigate immediately — no Future.delayed before pushNamed.
          // iOS requires the link to be consumed instantly to avoid Safari fallback.
          // Token validation can happen inside the target screen.
          final routeName = isPinReset ? '/reset-pin' : '/reset-password';
          navigatorKey.currentState?.pushNamed(
            routeName,
            arguments: {'token': token, 'identifier': identifier},
          );
        }
      }
    }

    Future.delayed(const Duration(seconds: 2), () {
      _isHandlingLink = false;
      _processedUri = null;
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
