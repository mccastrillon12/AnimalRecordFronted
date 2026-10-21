import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/widgets/menus/app_single_action_popup_menu.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/shared_files/presentation/shared_file_upload_feedback.dart';
import 'package:animal_record/features/shared_files/presentation/shared_file_upload_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnimalDocumentUploadMenu extends StatelessWidget {
  static const _menuCloseDuration = Duration(milliseconds: 320);

  final String animalId;
  final MedicalDocumentCategory? requestedCategory;
  final VoidCallback? onUploaded;
  final ValueChanged<MedicalDocumentCategory>? onUploadedToCategory;

  const AnimalDocumentUploadMenu({
    super.key,
    required this.animalId,
    this.requestedCategory,
    this.onUploaded,
    this.onUploadedToCategory,
  });

  @override
  Widget build(BuildContext context) {
    return AppSingleActionPopupMenu(
      menuKey: const Key('animal-document-upload-menu'),
      itemKey: const Key('upload-animal-document-menu-item'),
      value: 'subir_documento',
      label: 'Subir archivos',
      iconAsset: 'assets/icons/document-upload.svg',
      offset: const Offset(0, -68),
      onSelected: (value) => _handleSelection(context, value),
      trigger: Container(
        width: AppSpacing.iconSizeMedium,
        height: AppSpacing.iconSizeMedium,
        decoration: BoxDecoration(
          color: AppColors.secondaryCoral,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryCoral.withValues(alpha: 0.4),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          color: AppColors.white,
          size: AppSpacing.iconSizeSmall,
        ),
      ),
    );
  }

  Future<void> _handleSelection(BuildContext context, String value) async {
    if (value != 'subir_documento') return;

    final matches = context.read<AnimalCubit>().animals.where(
      (animal) => animal.id == animalId,
    );
    if (matches.isEmpty) {
      ErrorDisplay.showError(
        context,
        'No fue posible cargar la información del animal.',
      );
      return;
    }

    // PopupMenu completes its Future before the 300 ms reverse animation ends.
    // The extra frame prevents the upload route from overlapping its last paint.
    await Future<void>.delayed(_menuCloseDuration);
    if (!context.mounted) return;

    final uploaded = await Navigator.pushNamed(
      context,
      AppRoutes.sharedFileUpload,
      arguments: {
        'manualUpload': true,
        'preselectedAnimal': matches.first,
        sharedFileReturnUploadResultArgument: true,
        if (requestedCategory != null) 'requestedCategory': requestedCategory,
      },
    );
    if (!context.mounted) return;
    if (uploaded == true || uploaded is SharedFileUploadResult) {
      final savedCategory = uploaded is SharedFileUploadResult
          ? uploaded.category ?? requestedCategory
          : requestedCategory;
      if (savedCategory != null) onUploadedToCategory?.call(savedCategory);
      onUploaded?.call();
      final navigator = Navigator.of(context);
      if (uploaded is SharedFileUploadResult &&
          savedCategory != null &&
          savedCategory != requestedCategory) {
        final destination = resolveSharedFileUploadDestination(uploaded);
        if (destination?.sectionRouteName case final sectionRouteName?) {
          navigator.pushReplacementNamed(
            sectionRouteName,
            arguments: destination!.sectionArguments,
          );
        } else if (destination != null) {
          navigator.pop();
        }
      }
      _showTopSuccessAfterNavigation(navigator);
    } else if (uploaded == false) {
      final overlay = Navigator.of(context).overlay;
      if (overlay != null) {
        ErrorDisplay.showErrorOnOverlay(overlay, sharedFileUploadErrorMessage);
      }
    }
  }

  void _showTopSuccessAfterNavigation(NavigatorState navigator) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = navigator.overlay;
      if (overlay == null) return;
      ErrorDisplay.showSuccessOnOverlay(
        overlay,
        'El archivo ha sido subido exitosamente.',
      );
    });
  }
}
