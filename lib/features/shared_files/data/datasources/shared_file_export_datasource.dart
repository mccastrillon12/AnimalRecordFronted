import 'package:animal_record/features/shared_files/data/services/shared_file_pdf_builder.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class SharedFileExportDataSource {
  Future<void> exportAnalysisPdf(SharedFileAnalysisEntity analysis);

  Future<bool> saveAnalysisPdfs(
    List<SharedFileAnalysisEntity> analyses, {
    required String fileName,
  });
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
    final bytes = await pdfBuilder.build(
      analysis: analysis,
      logoBytes: await _logoBytes(),
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

  @override
  Future<bool> saveAnalysisPdfs(
    List<SharedFileAnalysisEntity> analyses, {
    required String fileName,
  }) async {
    if (analyses.isEmpty) return false;
    final bytes = await pdfBuilder.buildMany(
      analyses: analyses,
      logoBytes: await _logoBytes(),
    );
    final result = await FilePicker.saveFile(
      dialogTitle: 'Guardar historias clínicas',
      fileName: _pdfFileName(fileName),
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: bytes,
    );
    return result != null;
  }

  String _safeFileName(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áéíóúüñ]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'documento_animal_record' : normalized;
  }

  String _pdfFileName(String value) {
    final safeName = _safeFileName(value);
    return safeName.endsWith('.pdf') ? safeName : '$safeName.pdf';
  }

  Future<Uint8List> _logoBytes() async {
    final data = await rootBundle.load('assets/Logo/Logotipo_azul.png');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
