import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/features/medical_documents/presentation/cubit/medical_document_flow_cubit.dart';
import 'package:animal_record/features/shared_files/presentation/pages/shared_file_upload_screen.dart';
import 'package:animal_record/features/shared_files/presentation/shared_file_upload_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

PageRouteBuilder<Object?> buildSharedFileUploadRoute(RouteSettings settings) {
  assert(settings.name == AppRoutes.sharedFileUpload);
  final arguments = settings.arguments;
  final isExternalShare =
      arguments is Map && arguments[sharedFileExternalUploadArgument] == true;

  return PageRouteBuilder<Object?>(
    settings: settings,
    opaque: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: isExternalShare
        ? Duration.zero
        : const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
      create: (_) => di.sl<MedicalDocumentFlowCubit>(),
      child: const SharedFileUploadScreen(),
    ),
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
