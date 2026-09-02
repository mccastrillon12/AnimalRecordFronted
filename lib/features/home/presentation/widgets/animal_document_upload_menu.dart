import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/widgets/menus/app_single_action_popup_menu.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/shared_files/presentation/shared_file_upload_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnimalDocumentUploadMenu extends StatelessWidget {
  static const _menuCloseDuration = Duration(milliseconds: 320);

  final String animalId;
  final MedicalDocumentCategory? requestedCategory;
  final VoidCallback? onUploaded;

  const AnimalDocumentUploadMenu({
    super.key,
    required this.animalId,
    this.requestedCategory,
    this.onUploaded,
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
        if (requestedCategory != null) 'requestedCategory': requestedCategory,
      },
    );
    if (!context.mounted) return;
    if (uploaded == true) {
      onUploaded?.call();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ErrorDisplay.showSuccess(
          context,
          'El archivo ha sido subido exitosamente.',
        );
      });
    } else if (uploaded == false) {
      ErrorDisplay.showError(context, sharedFileUploadErrorMessage);
    }
  }
}
