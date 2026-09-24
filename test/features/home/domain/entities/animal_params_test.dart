import 'package:animal_record/features/home/domain/entities/create_animal_params.dart';
import 'package:animal_record/features/home/domain/entities/update_animal_params.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('create sends every animal name with capitalized words', () {
    const params = CreateAnimalParams(
      id: 'animal-1',
      name: 'juan pABLo',
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

    expect(params.toJson()['name'], 'Juan Pablo');
  });

  test('update sends every animal name with capitalized words', () {
    const params = UpdateAnimalParams(
      id: 'animal-1',
      name: 'mARIA jOSÉ',
      species: 'DOG',
      breed: 'Mestizo',
      sex: 'FEMALE',
      reproductiveStatus: 'STERILIZED',
      hasChip: false,
      isAssociationMember: false,
      temperament: [],
      diagnosis: [],
      ownerId: 'owner-1',
    );

    expect(params.toJson()['name'], 'Maria José');
  });
}
