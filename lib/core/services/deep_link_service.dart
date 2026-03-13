import 'dart:async';
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
      // FIX 1: use getInitialAppLink() instead of getInitialLink() for Universal Links on iOS
      final initialLink = await _appLinks.getInitialAppLink();
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


  Uri? _lastUri;
  bool _isHandlingLink = false;
  bool get isHandlingDeepLink => _isHandlingLink;

  void _waitForNavigatorAndHandle(
    Uri uri,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    // FIX 2: mark as handling BEFORE any await so iOS doesn't timeout and open Safari
    if (_isHandlingLink) return;
    _isHandlingLink = true;
    _lastUri = uri;

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
          // FIX 3: Navigate immediately without any async token validation delay.
          // iOS requires the link to be consumed instantly — no Future.delayed before pushNamed.
          // Any token validation should happen inside the target screen.
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
      _lastUri = null;
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
