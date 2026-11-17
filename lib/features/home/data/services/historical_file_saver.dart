import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:animal_record/features/home/domain/services/historical_file_save_service.dart';

class HistoricalFileSaver implements HistoricalFileSaveService {
  static const _mobileDownloads = MethodChannel(
    'com.animalrecord/file_download',
  );

  @override
  Future<bool> save(List<int> downloadedBytes, String suggestedName) async {
    if (downloadedBytes.isEmpty) throw const FormatException('Archivo vacío');
    final bytes = Uint8List.fromList(downloadedBytes);
    final safeName = suggestedName.trim().replaceAll(
      RegExp(r'[<>:"/\\|?*\x00-\x1F]'),
      '_',
    );
    final fileName = safeName.isEmpty ? 'historico.bin' : safeName;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final result = await _mobileDownloads.invokeMethod<String>('saveFile', {
        'fileName': fileName,
        'mimeType': 'application/octet-stream',
        'bytes': bytes,
      });
      return result != null;
    }
    return await FilePicker.saveFile(
          dialogTitle: 'Guardar archivo histórico',
          fileName: fileName,
          type: FileType.any,
          bytes: bytes,
        ) !=
        null;
  }
}
