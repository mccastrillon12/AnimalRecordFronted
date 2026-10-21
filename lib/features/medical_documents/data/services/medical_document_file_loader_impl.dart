import 'dart:typed_data';

import 'package:animal_record/features/medical_documents/domain/services/medical_document_file_loader.dart';
import 'package:dio/dio.dart';

class MedicalDocumentFileLoaderImpl implements MedicalDocumentFileLoader {
  final Dio dio;

  const MedicalDocumentFileLoaderImpl({required this.dio});

  @override
  Future<Uint8List> load(Uri remoteUri) async {
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
}
