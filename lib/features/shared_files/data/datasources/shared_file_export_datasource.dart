import 'package:animal_record/features/shared_files/data/services/shared_file_pdf_builder.dart';
import 'package:animal_record/features/shared_files/data/services/shared_file_image_pdf_converter.dart';
import 'package:animal_record/features/shared_files/data/services/shared_file_pdf_merger.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class SharedFileExportDataSource {
  Future<bool> exportAnalysisPdf(SharedFileAnalysisEntity analysis);

  Future<bool> saveAnalysisPdfs(
    List<SharedFileAnalysisEntity> analyses, {
    required String fileName,
  });
}

class SharedFileExportDataSourceImpl implements SharedFileExportDataSource {
  final SharedFilePdfBuilder pdfBuilder;
  final SharePlus sharePlus;
  final Dio dio;
  final SharedFilePdfMerger pdfMerger;
  final SharedFileImagePdfConverter imagePdfConverter;

  SharedFileExportDataSourceImpl({
    required this.pdfBuilder,
    required this.sharePlus,
    Dio? dio,
    SharedFilePdfMerger? pdfMerger,
    SharedFileImagePdfConverter? imagePdfConverter,
  }) : dio = dio ?? Dio(),
       pdfMerger = pdfMerger ?? SharedFilePdfMerger(),
       imagePdfConverter = imagePdfConverter ?? SharedFileImagePdfConverter();

  @override
  Future<bool> exportAnalysisPdf(SharedFileAnalysisEntity analysis) async {
    final summary = await pdfBuilder.build(
      analysis: analysis,
      logoBytes: await _logoBytes(),
    );
    final bytes = await _withOriginals(summary, analysis);
    final fileName = '${_safeFileName(analysis.documentType)}.pdf';

    final result = await sharePlus.share(
      ShareParams(
        title: 'Enviar ${analysis.documentType}',
        subject: analysis.documentType,
        text: 'Documento generado desde Animal Record.',
        files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
        fileNameOverrides: [fileName],
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
      ),
    );
    return result.status == ShareResultStatus.success;
  }

  @override
  Future<bool> saveAnalysisPdfs(
    List<SharedFileAnalysisEntity> analyses, {
    required String fileName,
  }) async {
    if (analyses.isEmpty) return false;
    final logoBytes = await _logoBytes();
    final documents = <Uint8List>[];
    for (final analysis in analyses) {
      final summary = await pdfBuilder.build(
        analysis: analysis,
        logoBytes: logoBytes,
      );
      documents.addAll(await _documentsWithOriginals(summary, analysis));
    }
    final bytes = await pdfMerger.merge(documents);
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

  Future<Uint8List> _withOriginals(
    Uint8List summary,
    SharedFileAnalysisEntity analysis,
  ) async {
    final documents = await _documentsWithOriginals(summary, analysis);
    return documents.length == 1 ? summary : pdfMerger.merge(documents);
  }

  Future<List<Uint8List>> _documentsWithOriginals(
    Uint8List summary,
    SharedFileAnalysisEntity analysis,
  ) async {
    final result = <Uint8List>[summary];
    final originals = <({String url, String? mimeType})>[
      if (analysis.originalUrl?.trim().isNotEmpty == true)
        (
          url: analysis.originalUrl!.trim(),
          mimeType: analysis.originalMimeType,
        ),
      for (final medication in analysis.medications)
        if (medication.originalUrl?.trim().isNotEmpty == true)
          (
            url: medication.originalUrl!.trim(),
            mimeType: medication.originalMimeType,
          ),
    ];
    final seenUrls = <String>{};
    for (final original in originals) {
      if (!seenUrls.add(original.url)) continue;
      final response = await dio.get<List<int>>(
        original.url,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null || data.isEmpty) {
        throw const FormatException('El archivo original está vacío.');
      }
      final bytes = Uint8List.fromList(data);
      final mimeType = _mimeType(
        original.mimeType,
        response.headers.value(Headers.contentTypeHeader),
        analysis.originalFileName,
        original.url,
      );
      result.add(
        mimeType.startsWith('image/')
            ? await imagePdfConverter.convert(bytes)
            : bytes,
      );
    }
    return result;
  }

  String _mimeType(
    String? declared,
    String? responseType,
    String fileName,
    String url,
  ) {
    for (final value in [declared, responseType]) {
      final normalized = value?.split(';').first.trim().toLowerCase() ?? '';
      if (normalized.isNotEmpty && normalized != 'application/octet-stream') {
        return normalized;
      }
    }
    final source = '${fileName.toLowerCase()} ${url.toLowerCase()}';
    if (RegExp(r'\.(jpe?g)(?:\?|\s|$)').hasMatch(source)) {
      return 'image/jpeg';
    }
    if (RegExp(r'\.png(?:\?|\s|$)').hasMatch(source)) return 'image/png';
    return 'application/pdf';
  }
}
