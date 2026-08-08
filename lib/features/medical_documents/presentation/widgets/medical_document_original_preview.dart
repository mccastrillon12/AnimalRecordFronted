import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/widgets/media/image_preview_dialog.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class MedicalDocumentOriginalPreview {
  final GetMedicalDocumentDownloadUriUseCase getDownloadUriUseCase;

  const MedicalDocumentOriginalPreview({required this.getDownloadUriUseCase});

  Future<void> show(
    BuildContext context, {
    SharedFileEntity? localFile,
    String? acceptedDocumentId,
    required String mimeType,
  }) async {
    Uri? remoteUri;
    if (localFile == null && acceptedDocumentId != null) {
      remoteUri = await getDownloadUriUseCase(acceptedDocumentId);
    }
    if (!context.mounted) return;

    final isPdf = mimeType.toLowerCase() == 'application/pdf';
    if (isPdf) {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.transparent,
        builder: (_) =>
            _PdfPreviewDialog(localFile: localFile, remoteUri: remoteUri),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => ImagePreviewDialog(
        imageUrl: remoteUri?.toString() ?? localFile?.path ?? '',
        imageBytes: localFile?.bytes,
      ),
    );
  }
}

class _PdfPreviewDialog extends StatelessWidget {
  final SharedFileEntity? localFile;
  final Uri? remoteUri;

  const _PdfPreviewDialog({this.localFile, this.remoteUri});

  @override
  Widget build(BuildContext context) {
    final viewer = _buildViewer();
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.black.withValues(alpha: 0.85)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColoredBox(color: AppColors.white, child: viewer),
              ),
            ),
          ),
          Positioned(
            top: 54,
            right: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewer() {
    final file = localFile;
    if (file?.bytes != null && file!.bytes!.isNotEmpty) {
      return PdfViewer.data(file.bytes!, sourceName: file.name);
    }
    if (file != null && file.path.isNotEmpty) {
      return PdfViewer.file(file.path);
    }
    if (remoteUri != null) return PdfViewer.uri(remoteUri!);
    return const Center(child: Text('No fue posible abrir el documento.'));
  }
}
