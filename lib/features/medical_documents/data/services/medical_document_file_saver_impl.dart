import 'dart:io';
import 'dart:typed_data';

import 'package:animal_record/features/medical_documents/domain/services/medical_document_file_saver.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show MethodChannel;

typedef MedicalDocumentSaveBytes =
    Future<String?> Function({
      required String fileName,
      required String mimeType,
      required Uint8List bytes,
    });

class MedicalDocumentFileSaverImpl implements MedicalDocumentFileSaver {
  static const _mobileDownloadChannel = MethodChannel(
    'com.animalrecord/file_download',
  );

  final Dio dio;
  final MedicalDocumentSaveBytes saveBytes;

  MedicalDocumentFileSaverImpl({
    required this.dio,
    MedicalDocumentSaveBytes? saveBytes,
  }) : saveBytes = saveBytes ?? _saveBytes;

  @override
  Future<bool> save(MedicalDocumentFileSaveRequest request) async {
    final bytes = await _loadBytes(request);
    final result = await saveBytes(
      fileName: _safeFileName(request.fileName),
      mimeType: request.mimeType,
      bytes: bytes,
    );
    return result != null;
  }

  Future<Uint8List> _loadBytes(MedicalDocumentFileSaveRequest request) async {
    if (request.bytes case final bytes? when bytes.isNotEmpty) return bytes;

    final localPath = request.localPath?.trim() ?? '';
    if (localPath.isNotEmpty) return File(localPath).readAsBytes();

    final remoteUri = request.remoteUri;
    if (remoteUri == null) {
      throw const FormatException('No hay un archivo disponible para guardar.');
    }
    final response = await dio.getUri<List<int>>(
      remoteUri,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw const FormatException('El archivo descargado está vacío.');
    }
    return Uint8List.fromList(data);
  }

  static Future<String?> _saveBytes({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    if (Platform.isAndroid || Platform.isIOS) {
      return _mobileDownloadChannel.invokeMethod<String>('saveFile', {
        'fileName': fileName,
        'mimeType': mimeType,
        'bytes': bytes,
      });
    }

    final extension = _fileExtension(fileName) ?? 'pdf';
    return FilePicker.saveFile(
      dialogTitle: 'Guardar archivo',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [extension],
      bytes: bytes,
    );
  }

  String _safeFileName(String value) {
    var name = value.trim().replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');
    if (name.isEmpty) name = 'documento_medico.pdf';
    if (_fileExtension(name) == null) name = '$name.pdf';
    return name;
  }

  static String? _fileExtension(String fileName) {
    final match = RegExp(r'\.([a-zA-Z0-9]{1,10})$').firstMatch(fileName.trim());
    return match?.group(1)?.toLowerCase();
  }
}
