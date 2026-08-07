import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/features/shared_files/presentation/pages/shared_file_upload_screen.dart';
import 'package:flutter/material.dart';

PageRouteBuilder<void> buildSharedFileUploadRoute(RouteSettings settings) {
  assert(settings.name == AppRoutes.sharedFileUpload);

  return PageRouteBuilder<void>(
    settings: settings,
    opaque: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const SharedFileUploadScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
        child: child,
      );
    },
  );
}
