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

  ValidatePasswordTokenUseCase? _validatePasswordTokenUseCase;

  void setValidatePasswordTokenUseCase(ValidatePasswordTokenUseCase useCase) {
    _validatePasswordTokenUseCase = useCase;
  }

  Uri? _lastUri;
  bool _isHandlingLink = false;

  void _handleLink(Uri uri, GlobalKey<NavigatorState> navigatorKey) async {
    if (_isHandlingLink) return;
    _isHandlingLink = true;

    // Check against last handled URI to prevent double processing of the exact same link immediately
    if (uri == _lastUri) {
      _isHandlingLink = false;
      return;
    }
    _lastUri = uri;

    debugPrint('Received Deep Link: $uri');

    // Handle password reset
    // Format: https://animalrecord.app/reset-password?token=...
    if (uri.path == '/reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        final identifier =
            uri.queryParameters['identifier'] ?? uri.queryParameters['email'];

        if (navigatorKey.currentState != null &&
            _validatePasswordTokenUseCase != null) {
          final context = navigatorKey.currentState!.context;

          // Show transparent loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black.withOpacity(0.5),
            builder: (ctx) => const Center(child: CircularProgressIndicator()),
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
                navigatorKey.currentState?.pushNamed(
                  '/reset-password',
                  arguments: {'token': token, 'identifier': identifier},
                );
              } else {
                navigatorKey.currentState?.pushNamed('/link-expired');
              }
            },
          );
        } else if (navigatorKey.currentState != null) {
          // Fallback if usecase is not set
          navigatorKey.currentState?.pushNamed(
            '/reset-password',
            arguments: {'token': token, 'identifier': identifier},
          );
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
