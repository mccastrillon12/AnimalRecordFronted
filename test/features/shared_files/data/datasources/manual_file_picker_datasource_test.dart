import 'dart:typed_data';

import 'package:animal_record/features/shared_files/data/datasources/manual_file_picker_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class MockImagePicker extends Mock implements ImagePicker {}

class MockXFile extends Mock implements XFile {}

void main() {
  late MockImagePicker imagePicker;

  setUp(() {
    imagePicker = MockImagePicker();
  });

  test('convierte una foto HEIC a JPEG antes de devolverla', () async {
    final sourceBytes = Uint8List.fromList([1, 2, 3]);
    final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);
    final selectedPhoto = MockXFile();
    Uint8List? convertedBytes;
    when(() => selectedPhoto.name).thenReturn('vacaciones.heic');
    when(() => selectedPhoto.path).thenReturn('/tmp/vacaciones.heic');
    when(
      () => selectedPhoto.readAsBytes(),
    ).thenAnswer((_) async => sourceBytes);
    when(
      () =>
          imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 100),
    ).thenAnswer((_) async => selectedPhoto);
    final dataSource = ManualFilePickerDataSourceImpl(
      imagePicker: imagePicker,
      photoToJpegConverter: (bytes) async {
        convertedBytes = bytes;
        return jpegBytes;
      },
    );

    final result = await dataSource.pickFromPhotos();

    expect(convertedBytes, sourceBytes);
    expect(result?['name'], 'vacaciones.jpg');
    expect(result?['mimeType'], 'image/jpeg');
    expect(result?['size'], jpegBytes.length);
    expect(result?['bytes'], jpegBytes);
  });

  test('conserva la cancelación del selector de fotos', () async {
    when(
      () =>
          imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 100),
    ).thenAnswer((_) async => null);
    final dataSource = ManualFilePickerDataSourceImpl(
      imagePicker: imagePicker,
      photoToJpegConverter: (bytes) async => bytes,
    );

    expect(await dataSource.pickFromPhotos(), isNull);
  });
}
