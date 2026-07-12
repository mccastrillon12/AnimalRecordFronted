import 'package:file_picker/file_picker.dart';

abstract interface class ManualFilePickerDataSource {
  Future<Map<Object?, Object?>?> pickFile();
}

class ManualFilePickerDataSourceImpl implements ManualFilePickerDataSource {
  const ManualFilePickerDataSourceImpl();

  @override
  Future<Map<Object?, Object?>?> pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'pdf'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final extension = file.extension?.toLowerCase();
    final mimeType = switch (extension) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };

    return {
      'path': file.path ?? '',
      'name': file.name,
      'mimeType': mimeType,
      'size': file.size,
      'bytes': file.bytes,
    };
  }
}
