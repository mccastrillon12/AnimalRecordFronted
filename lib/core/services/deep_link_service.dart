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

    if (uri == _lastUri) {
      _isHandlingLink = false;
      return;
    }
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
        final identifier =
            uri.queryParameters['identifier'] ?? uri.queryParameters['email'];

        if (navigatorKey.currentState != null) {
          if (isPinReset) {
            navigatorKey.currentState?.pushNamed(
              '/reset-pin',
              arguments: {'token': token, 'identifier': identifier},
            );
            return;
          }

          if (_validatePasswordTokenUseCase != null) {
            final context = navigatorKey.currentState!.context;

            showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.black54,
              builder: (ctx) =>
                  const Center(child: CircularProgressIndicator()),
            );

            await Future.delayed(const Duration(milliseconds: 250));

            final result = await _validatePasswordTokenUseCase!(
              identifier ?? '',
              token,
            );

            if (navigatorKey.currentState?.canPop() == true) {
              navigatorKey.currentState?.pop();
            }

            result.fold(
              (failure) {
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

    Future.delayed(const Duration(seconds: 2), () {
      _isHandlingLink = false;

      _lastUri = null;
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
