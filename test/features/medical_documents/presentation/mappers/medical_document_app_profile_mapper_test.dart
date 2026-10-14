import 'package:animal_record/features/auth/domain/entities/user_entity.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_app_profile_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps patient and tutor exclusively from app profile data', () {
    const animal = AnimalModel(
      id: 'animal-1',
      name: 'Eithan',
      code: 'AR-C049',
      family: 'Canino',
      breed: 'Criollo',
      sex: 'macho',
      ageDisplay: '7-11 meses',
      weight: 15,
      colorAndMarkings: 'Café',
      ownerName: 'Nombre anterior',
    );
    final user = UserEntity.empty().copyWith(
      name: 'Barbara James',
      identificationType: 'CC',
      identificationNumber: '1152234567',
      cellPhone: '+57 312 456 7890',
      email: 'barbara@example.com',
    );

    final patient = sharedFilePatientFromAnimal(animal);
    final tutor = sharedFileTutorFromApp(user, animal);

    expect(patient.name, 'Eithan');
    expect(patient.recordId, 'AR-C049');
    expect(patient.species, 'Canino');
    expect(patient.breed, 'Criollo');
    expect(patient.sex, 'Macho');
    expect(patient.color, 'Café');
    expect(patient.age, '7-11 meses');
    expect(patient.weight, '15 kg');
    expect(tutor.name, 'Barbara James');
    expect(tutor.identification, 'C.C. 1152234567');
    expect(tutor.phoneNumber, '(+57) 3124567890');
    expect(tutor.email, 'barbara@example.com');
  });
}
