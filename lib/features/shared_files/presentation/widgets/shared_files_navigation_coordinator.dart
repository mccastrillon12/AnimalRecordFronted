import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_cubit.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_state.dart';
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
    await navigator.pushNamed(AppRoutes.sharedFileUpload);
    if (mounted) _isPresenting = false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SharedFilesCubit, SharedFilesState>(
      listener: _handleSharedFiles,
      child: widget.child,
    );
  }
}
