import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnimalModel.fromEntity', () {
    test('conserva los datos y aplica el formato visual actual', () {
      const entity = AnimalEntity(
        id: 'animal-1234',
        name: '  lUNA  ',
        species: 'CAT',
        breed: 'Criollo',
        sex: 'FEMALE',
        reproductiveStatus: 'STERILIZED',
        hasChip: true,
        isAssociationMember: false,
        temperament: ['CALM'],
        diagnosis: ['NONE'],
        ownerId: 'owner-1',
        profilePictureUrl: 'https://example.com/luna.jpg',
      );

      final result = AnimalModel.fromEntity(entity);

      expect(result.id, entity.id);
      expect(result.name, 'Luna');
      expect(result.code, 'AR-ANIM');
      expect(result.family, 'Felino');
      expect(result.sex, 'hembra');
      expect(result.sexDisplay, 'Hembra');
      expect(result.imageUrl, entity.profilePictureUrl);
      expect(result.temperament, entity.temperament);
      expect(result.diagnosis, entity.diagnosis);
    });

    test('mantiene la etiqueta de edad aproximada usada por la UI', () {
      const entity = AnimalEntity(
        id: 'animal-5678',
        name: 'Max',
        code: 'AR-001',
        species: 'DOG',
        breed: 'Mestizo',
        sex: 'MALE',
        reproductiveStatus: 'INTACT',
        hasChip: false,
        isAssociationMember: false,
        temperament: [],
        diagnosis: [],
        ownerId: 'owner-1',
        unknownBirthDate: true,
        approximateAgeMinMonths: 12,
        approximateAgeMaxMonths: 36,
      );

      final result = AnimalModel.fromEntity(entity);

      expect(result.code, 'AR-001');
      expect(result.family, 'Canino');
      expect(result.sex, 'macho');
      expect(result.ageDisplay, '1-3 años');
    });

    test('capitaliza cada palabra cuando el animal tiene varios nombres', () {
      const entity = AnimalEntity(
        id: 'animal-multiple-name',
        name: '  juAN   paBLo de la cruz  ',
        species: 'DOG',
        breed: 'Mestizo',
        sex: 'MALE',
        reproductiveStatus: 'INTACT',
        hasChip: false,
        isAssociationMember: false,
        temperament: [],
        diagnosis: [],
        ownerId: 'owner-1',
      );

      final result = AnimalModel.fromEntity(entity);

      expect(result.name, 'Juan Pablo De La Cruz');
    });

    test('excluye de la tarjeta los diagnósticos extraídos de documentos', () {
      const entity = AnimalEntity(
        id: 'animal-9012',
        name: 'Manchas',
        code: 'AR-B017',
        species: 'BOVINE',
        breed: 'Cebú',
        sex: 'MALE',
        reproductiveStatus: 'INTACT',
        hasChip: false,
        isAssociationMember: false,
        temperament: ['Agresivo'],
        diagnosis: [
          'Ninguno/Desconocido',
          'Enteritis linfoplasmocitaria',
          'Colitis',
          'Enterocolitis crónica',
        ],
        ownerId: 'owner-1',
      );

      final result = AnimalModel.fromEntity(entity);

      expect(result.diagnosis, const ['Ninguno/Desconocido']);
    });
  });
}
