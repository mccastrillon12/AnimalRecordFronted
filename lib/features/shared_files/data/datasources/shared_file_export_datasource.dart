import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/features/shared_files/data/services/shared_file_pdf_builder.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class SharedFileExportDataSource {
  Future<void> exportAnalysisPdf(SharedFileAnalysisEntity analysis);
}

class SharedFileExportDataSourceImpl implements SharedFileExportDataSource {
  final SharedFilePdfBuilder pdfBuilder;
  final SharePlus sharePlus;

  const SharedFileExportDataSourceImpl({
    required this.pdfBuilder,
    required this.sharePlus,
  });

  @override
  Future<void> exportAnalysisPdf(SharedFileAnalysisEntity analysis) async {
    final clipboardSvg = await rootBundle.loadString(AppIcons.clipboardImport);
    final bytes = await pdfBuilder.build(
      analysis: analysis,
      clipboardSvg: clipboardSvg,
    );
    final fileName = '${_safeFileName(analysis.documentType)}.pdf';

    await sharePlus.share(
      ShareParams(
        title: 'Enviar ${analysis.documentType}',
        subject: analysis.documentType,
        text: 'Documento generado desde Animal Record.',
        files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
        fileNameOverrides: [fileName],
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
      ),
    );
  }

  String _safeFileName(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áéíóúüñ]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'documento_animal_record' : normalized;
  }
}
