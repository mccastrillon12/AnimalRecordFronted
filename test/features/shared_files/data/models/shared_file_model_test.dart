import 'package:animal_record/features/shared_files/data/models/shared_file_model.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SharedFileModel.fromMap', () {
    test('convierte un PDF recibido por la plataforma', () {
      final model = SharedFileModel.fromMap(const {
        'path': '/tmp/document.pdf',
        'name': 'document.pdf',
        'mimeType': 'application/pdf',
      });

      expect(model.path, '/tmp/document.pdf');
      expect(model.name, 'document.pdf');
      expect(model.mimeType, 'application/pdf');
      expect(model.type, SharedFileType.pdf);
    });

    test('convierte una imagen recibida por la plataforma', () {
      final model = SharedFileModel.fromMap(const {
        'path': '/tmp/photo.jpg',
        'name': 'photo.jpg',
        'mimeType': 'image/jpeg',
      });

      expect(model.type, SharedFileType.image);
    });
  });
}
