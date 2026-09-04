import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/shared_files/presentation/shared_file_upload_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes one animal through its detail and prescription section', () {
    final destination = resolveSharedFileUploadDestination(
      const SharedFileUploadResult(
        animals: [_animal],
        category: MedicalDocumentCategory.prescription,
      ),
    );

    expect(destination, isNotNull);
    expect(destination!.animal.id, _animal.id);
    expect(destination.sectionRouteName, AppRoutes.animalDocuments);
    expect(destination.sectionArguments, {
      'animalId': _animal.id,
      'initialCategory': MedicalDocumentCategory.prescription,
    });
  });

  test('routes one animal to the detected clinical section', () {
    final destination = resolveSharedFileUploadDestination(
      const SharedFileUploadResult(
        animals: [_animal],
        category: MedicalDocumentCategory.clinicalHistory,
      ),
    );

    expect(destination, isNotNull);
    expect(destination!.animal.id, _animal.id);
    expect(destination.sectionRouteName, AppRoutes.animalClinicalHistory);
    expect(destination.sectionArguments, same(destination.animal));
  });

  test('keeps multiple animals in My animals without a detail route', () {
    final destination = resolveSharedFileUploadDestination(
      const SharedFileUploadResult(
        animals: [_animal, _secondAnimal],
        category: MedicalDocumentCategory.prescription,
      ),
    );

    expect(destination, isNull);
  });
}

const _animal = AnimalEntity(
  id: 'animal-1',
  name: 'Umi',
  code: 'AR-F025',
  species: 'CAT',
  breed: 'Criollo',
  sex: 'FEMALE',
  reproductiveStatus: 'SPAYED',
  hasChip: false,
  isAssociationMember: false,
  temperament: [],
  diagnosis: [],
  ownerId: 'owner-1',
);

const _secondAnimal = AnimalEntity(
  id: 'animal-2',
  name: 'Bruno',
  code: 'AR-C012',
  species: 'DOG',
  breed: 'Labrador',
  sex: 'MALE',
  reproductiveStatus: 'INTACT',
  hasChip: false,
  isAssociationMember: false,
  temperament: [],
  diagnosis: [],
  ownerId: 'owner-1',
);
