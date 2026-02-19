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
    // Check initial link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleLink(initialLink, navigatorKey);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Listen to incoming links
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleLink(uri, navigatorKey),
      onError: (err) => debugPrint('Deep Link Error: $err'),
    );
  }

  Uri? _lastUri;

  void _handleLink(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
    if (uri == _lastUri) return;
    _lastUri = uri;

    debugPrint('Received Deep Link: $uri');

    // Handle password reset
    // Format: https://animalrecord.app/reset-password?token=...
    if (uri.path == '/reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        // Navigate to Reset Password Screen with token and identifier
        // We use a slight delay to ensure the app is ready if it was just launched
        Future.delayed(const Duration(milliseconds: 500), () {
          final identifier =
              uri.queryParameters['identifier'] ?? uri.queryParameters['email'];
          navigatorKey.currentState?.pushNamed(
            '/reset-password',
            arguments: {'token': token, 'identifier': identifier},
          );
        });
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
