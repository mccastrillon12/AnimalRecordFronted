import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/features/shared_files/presentation/navigation/shared_file_upload_route.dart';
import 'package:animal_record/features/shared_files/presentation/shared_file_upload_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the previous screen visible while upload route opens', () {
    const settings = RouteSettings(
      name: AppRoutes.sharedFileUpload,
      arguments: {'manualUpload': true},
    );

    final route = buildSharedFileUploadRoute(settings);

    expect(route.settings, same(settings));
    expect(route.opaque, isFalse);
    expect(route.barrierColor, Colors.transparent);
    expect(route.transitionDuration, const Duration(milliseconds: 220));
    expect(route.reverseTransitionDuration, const Duration(milliseconds: 180));
  });

  test('external upload closes without exposing intermediate screens', () {
    const settings = RouteSettings(
      name: AppRoutes.sharedFileUpload,
      arguments: {sharedFileExternalUploadArgument: true},
    );

    final route = buildSharedFileUploadRoute(settings);

    expect(route.reverseTransitionDuration, Duration.zero);
  });
}
