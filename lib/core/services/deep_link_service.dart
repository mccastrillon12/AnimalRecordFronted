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

  // URI captured on cold start, waiting for the navigator to be ready.
  // SplashScreen calls consumePendingLink() when it finishes so there are
  // NO while-loops / delays that would trip iOS's ~1 s Universal Link timeout.
  Uri? _pendingUri;

  // Keep setValidatePasswordTokenUseCase for compatibility with main.dart
  ValidatePasswordTokenUseCase? _validatePasswordTokenUseCase;

  void setValidatePasswordTokenUseCase(ValidatePasswordTokenUseCase useCase) {
    _validatePasswordTokenUseCase = useCase;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initDeepLinks(GlobalKey<NavigatorState> navigatorKey) async {
    // Cold-start: capture the link that launched the app.
    // We store it as _pendingUri — SplashScreen will call consumePendingLink()
    // once it pushes the next route so we can navigate immediately, without any
    // busy-waiting that would cause iOS to fall back to Safari.
    try {
      // getInitialLink() is the standard cold-start link for app_links v6.x.
      // getLatestLink() is used as a fallback — on iOS, Universal Links sometimes
      // arrive via getLatestLink() when getInitialLink() returns null.
      final initialLink =
          await _appLinks.getInitialLink() ?? await _appLinks.getLatestLink();
      if (initialLink != null) {
        debugPrint('[DeepLink] Cold-start link captured: $initialLink');
        _pendingUri = initialLink;
      }
    } catch (e) {
      debugPrint('[DeepLink] Error reading initial link: $e');
    }

    // Warm-start / foreground: process links while the app is running.
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri, navigatorKey),
      onError: (err) => debugPrint('[DeepLink] Stream error: $err'),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public API used by SplashScreen
  // ─────────────────────────────────────────────────────────────────────────

  /// Call this from SplashScreen (or wherever the navigator first stabilises)
  /// to process the cold-start link immediately with zero delays.
  bool consumePendingLink(GlobalKey<NavigatorState> navigatorKey) {
    if (_pendingUri == null) return false;
    final uri = _pendingUri!;
    _pendingUri = null;
    debugPrint('[DeepLink] Consuming pending cold-start link: $uri');
    return _processLink(uri, navigatorKey);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal
  // ─────────────────────────────────────────────────────────────────────────

  void _handleUri(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
    debugPrint('[DeepLink] Warm-start link received: $uri');
    if (navigatorKey.currentState == null) {
      // Navigator not ready yet (very unlikely on warm-start); store as pending.
      _pendingUri = uri;
      return;
    }
    _processLink(uri, navigatorKey);
  }

  /// Navigates to the appropriate screen for [uri].
  /// Returns true if the link was handled.
  bool _processLink(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
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

        final routeName = isPinReset ? '/reset-pin' : '/reset-password';
        debugPrint('[DeepLink] Navigating to $routeName');

        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          routeName,
          (route) => route.settings.name == '/login' || route.isFirst,
          arguments: {'token': token, 'identifier': identifier},
        );
        return true;
      }
    }

    debugPrint('[DeepLink] Link not handled: $uri');
    return false;
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
