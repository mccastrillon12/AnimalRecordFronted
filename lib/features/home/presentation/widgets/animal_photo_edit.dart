import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/media/animal_photo_cropper.dart';

/// The edit affordance shown over an animal photo.
class AnimalPhotoEditButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AnimalPhotoEditButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Editar foto',
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: AppSpacing.xl,
          height: AppSpacing.xl,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: AppBorders.small(),
          ),
          child: const Icon(
            Icons.edit,
            color: Colors.white,
            size: AppSpacing.l,
          ),
        ),
      ),
    );
  }
}

enum _PhotoSourceAction { camera, gallery, remove }

/// Lets the user take, choose, or remove an animal photo.
///
/// Selected photos pass through the same cropper used during animal creation.
Future<void> showAnimalPhotoSourceSheet({
  required BuildContext context,
  required bool hasPhoto,
  required ValueChanged<String> onPhotoSelected,
  required VoidCallback onPhotoRemoved,
}) async {
  final action = await showModalBottomSheet<_PhotoSourceAction>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.greyBordes,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Foto del animal',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Tomar foto'),
                onTap: () =>
                    Navigator.pop(sheetContext, _PhotoSourceAction.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galería'),
                onTap: () =>
                    Navigator.pop(sheetContext, _PhotoSourceAction.gallery),
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.errorRojo,
                  ),
                  title: const Text(
                    'Eliminar foto',
                    style: TextStyle(color: AppColors.errorRojo),
                  ),
                  onTap: () =>
                      Navigator.pop(sheetContext, _PhotoSourceAction.remove),
                ),
            ],
          ),
        ),
      );
    },
  );

  if (!context.mounted || action == null) return;
  if (action == _PhotoSourceAction.remove) {
    onPhotoRemoved();
    return;
  }

  final picked = await ImagePicker().pickImage(
    source: action == _PhotoSourceAction.camera
        ? ImageSource.camera
        : ImageSource.gallery,
    maxWidth: 1920,
    maxHeight: 1920,
    imageQuality: 95,
  );
  if (picked == null || !context.mounted) return;

  final croppedPath = await showAnimalPhotoCropper(
    context,
    imagePath: picked.path,
  );
  if (croppedPath != null && context.mounted) {
    onPhotoSelected(croppedPath);
  }
}
