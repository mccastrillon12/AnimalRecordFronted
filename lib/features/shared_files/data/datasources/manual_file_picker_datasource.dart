import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

abstract interface class ManualFilePickerDataSource {
  Future<Map<Object?, Object?>?> pickFromFiles();

  Future<Map<Object?, Object?>?> pickFromPhotos();
}

class ManualFilePickerDataSourceImpl implements ManualFilePickerDataSource {
  final ImagePicker imagePicker;

  ManualFilePickerDataSourceImpl({ImagePicker? imagePicker})
    : imagePicker = imagePicker ?? ImagePicker();

  @override
  Future<Map<Object?, Object?>?> pickFromFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'pdf'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    return {
      'path': file.path ?? '',
      'name': file.name,
      'mimeType': _mimeType(file.extension),
      'size': file.size,
      'bytes': file.bytes,
    };
  }

  @override
  Future<Map<Object?, Object?>?> pickFromPhotos() async {
    final file = await imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    final bytes = await file.readAsBytes();

    return {
      'path': file.path,
      'name': file.name,
      'mimeType': _mimeType(file.name.split('.').last),
      'size': bytes.length,
      'bytes': bytes,
    };
  }

  String _mimeType(String? extension) {
    return switch (extension?.toLowerCase()) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
  }
}
