import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/features/home/presentation/navigation/home_section_navigation.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_cubit.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_state.dart';
import 'package:animal_record/features/shared_files/presentation/shared_file_upload_feedback.dart';
import 'package:animal_record/features/shared_files/presentation/shared_file_upload_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SharedFilesNavigationCoordinator extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const SharedFilesNavigationCoordinator({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<SharedFilesNavigationCoordinator> createState() =>
      _SharedFilesNavigationCoordinatorState();
}

class _SharedFilesNavigationCoordinatorState
    extends State<SharedFilesNavigationCoordinator> {
  bool _isPresenting = false;

  Future<void> _handleSharedFiles(
    BuildContext context,
    SharedFilesState state,
  ) async {
    if (state is! SharedFilesReceived || _isPresenting) return;

    final authState = context.read<AuthBloc>().state;
    final sharedFiles = context.read<SharedFilesCubit>();
    if (authState is AuthUnauthenticated || authState is AuthError) {
      sharedFiles.clear();
      return;
    }
    if (authState is! AuthSuccess || !sharedFiles.accessGranted) return;

    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;
    _isPresenting = true;
    final uploaded = await navigator.pushNamed(
      AppRoutes.sharedFileUpload,
      arguments: const {sharedFileExternalUploadArgument: true},
    );
    if (!mounted) return;
    _isPresenting = false;
    if (uploaded is SharedFileUploadResult || uploaded == true) {
      navigator.pushNamedAndRemoveUntil(
        AppRoutes.home,
        (_) => false,
        arguments: const {homeInitialSectionArgument: homeMyAnimalsSection},
      );
      if (uploaded is SharedFileUploadResult) {
        _openSingleAnimalUploadDestination(uploaded);
      } else {
        _showSuccessAfterNavigation();
      }
    } else if (uploaded == false) {
      navigator.pushNamedAndRemoveUntil(
        AppRoutes.home,
        (_) => false,
        arguments: const {homeInitialSectionArgument: homeMyAnimalsSection},
      );
      _showErrorAfterNavigation();
    }
  }

  void _openSingleAnimalUploadDestination(SharedFileUploadResult result) {
    final navigator = widget.navigatorKey.currentState;
    final destination = resolveSharedFileUploadDestination(result);
    if (navigator == null || destination == null) {
      _showSuccess();
      return;
    }

    navigator.pushNamed(AppRoutes.animalDetail, arguments: destination.animal);
    final sectionRouteName = destination.sectionRouteName;
    if (sectionRouteName != null) {
      navigator.pushNamed(
        sectionRouteName,
        arguments: destination.sectionArguments,
      );
    }
    _showSuccessAfterNavigation();
  }

  void _showSuccessAfterNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showSuccess();
    });
  }

  void _showErrorAfterNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final overlay = widget.navigatorKey.currentState?.overlay;
      if (overlay != null) {
        ErrorDisplay.showErrorOnOverlay(overlay, sharedFileUploadErrorMessage);
      }
    });
  }

  void _showSuccess() {
    final overlay = widget.navigatorKey.currentState?.overlay;
    if (overlay != null) {
      ErrorDisplay.showSuccessOnOverlay(
        overlay,
        sharedFileUploadSuccessMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SharedFilesCubit, SharedFilesState>(
      listener: _handleSharedFiles,
      child: widget.child,
    );
  }
}
