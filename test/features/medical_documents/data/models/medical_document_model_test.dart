import 'package:animal_record/features/medical_documents/data/models/medical_document_model.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the complete backend response without losing category data', () {
    final model = MedicalDocumentModel.fromJson({
      'id': 'document-1',
      'animalIds': ['animal-1', 'animal-2'],
      'originalFileName': 'formula.pdf',
      'mimeType': 'application/pdf',
      'fileSize': 2048,
      'status': 'REVIEW_PENDING',
      'requestedCategory': 'PRESCRIPTION',
      'primaryDetectedCategory': 'PRESCRIPTION',
      'classificationOutcome': 'MATCH_WITH_ADDITIONAL',
      'detectedCategories': [
        {
          'category': 'PRESCRIPTION',
          'confidence': 0.92,
          'pageStart': 1,
          'pageEnd': 2,
          'evidence': 'Fórmula médica',
        },
      ],
      'extractionsByCategory': {
        'PRESCRIPTION': {
          'documentType': 'PRESCRIPTION',
          'documentDate': '2026-01-25',
          'issuer': {
            'name': 'Dra. Natalia López',
            'clinic': 'Clínica Animal Record',
            'professionalId': 'MV-41611',
          },
          'patientHints': ['Brownie'],
          'diagnoses': [],
          'medications': [
            {
              'id': 'medication-1',
              'name': 'ProtectionPets',
              'dose': '2 gr',
              'source': {'page': 1, 'text': '2 gr cada 24 horas'},
            },
          ],
          'vaccinations': [],
          'medicalOrders': [],
          'additionalFields': {'clinic': 'Animal Record'},
          'warnings': [],
        },
      },
      'assignments': [],
      'version': 3,
      'createdAt': '2026-01-25T12:00:00.000Z',
      'updatedAt': '2026-01-25T12:01:00.000Z',
    });

    expect(model.id, 'document-1');
    expect(model.animalIds, ['animal-1', 'animal-2']);
    expect(model.status, MedicalDocumentStatus.reviewPending);
    expect(
      model.classificationOutcome,
      MedicalDocumentClassificationOutcome.matchWithAdditional,
    );
    expect(model.detectedCategories.single.pageEnd, 2);
    final extraction =
        model.extractionsByCategory[MedicalDocumentCategory.prescription]!;
    expect(extraction.medications.single.id, 'medication-1');
    expect(extraction.medications.single.name, 'ProtectionPets');
    expect(extraction.medications.single.source?.page, 1);
    expect(extraction.issuer?['name'], 'Dra. Natalia López');
    expect(extraction.additionalFields['clinic'], 'Animal Record');
    expect(model.version, 3);
  });

  test(
    'serializes an accepted review with exactly one assignment per animal',
    () {
      const extraction = MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.prescription,
        patientHints: ['Brownie'],
        medications: [
          MedicalDocumentItemEntity(
            id: 'medication-1',
            fields: {'name': 'ProtectionPets', 'route': 'oral'},
          ),
        ],
      );
      final payload = MedicalDocumentModel.reviewRequestToJson(
        ReviewMedicalDocumentRequest.accept(
          documentVersion: 4,
          finalCategory: MedicalDocumentCategory.prescription,
          validatedExtraction: extraction,
          assignments: const [
            MedicalDocumentAssignmentEntity(
              animalId: 'animal-1',
              extractedItemIds: ['medication-1'],
            ),
            MedicalDocumentAssignmentEntity(animalId: 'animal-2'),
          ],
        ),
      );

      expect(payload['decision'], 'ACCEPT');
      expect(payload['documentVersion'], 4);
      expect(payload['finalCategory'], 'PRESCRIPTION');
      final validated = payload['validatedExtraction'] as Map<String, dynamic>;
      expect(validated['documentType'], 'PRESCRIPTION');
      expect(validated['diagnoses'], isEmpty);
      expect(validated['vaccinations'], isEmpty);
      expect((payload['assignments'] as List), hasLength(2));
      expect(
        (payload['assignments'] as List).last['extractedItemIds'],
        isEmpty,
      );
    },
  );

  test(
    'normalizes the filename and parses animal data returned by backend',
    () {
      final model = MedicalDocumentModel.fromJson({
        'id': 'document-2',
        'animalIds': ['backend-animal'],
        'animalDetails': [
          {
            'id': 'backend-animal',
            'name': 'Brownie backend',
            'animalRecordId': 'AR-BACK',
            'species': 'CANINE',
            'race': 'Labrador',
            'age': '8 años',
            'weight': '18 kg',
          },
        ],
        'tutor': {
          'name': 'Barbara James',
          'identificationNumber': '1152234567',
          'cellPhone': '3124567890',
        },
        'originalFileName': 'OkVet FÃ³rmula mÃ©dica.pdf',
        'mimeType': 'application/pdf',
        'fileSize': 100,
        'status': 'ANALYZING',
        'detectedCategories': [],
        'extractionsByCategory': {},
        'assignments': [],
        'version': 1,
      });

      expect(model.originalFileName, 'OkVet Fórmula médica.pdf');
      expect(model.animalDetails.single.name, 'Brownie backend');
      expect(model.animalDetails.single.code, 'AR-BACK');
      expect(model.animalDetails.single.breed, 'Labrador');
      expect(model.tutorDetails?.name, 'Barbara James');
      expect(model.tutorDetails?.identification, '1152234567');
    },
  );

  test('parses nested patient and tutor values without UI fallbacks', () {
    final model = MedicalDocumentModel.fromJson({
      'id': 'document-3',
      'animalIds': ['backend-patient'],
      'animalDetails': {
        'id': 'backend-patient',
        'patientName': 'BENJI',
        'recordId': 'AR-B017',
        'species': {'name': 'Felino'},
        'race': {'label': 'Persa'},
        'weight': {'value': 6, 'unit': 'kg'},
        'owner': {
          'fullName': 'Andrea Pérez',
          'documentNumber': '123456',
          'mobile': '3001234567',
        },
      },
      'originalFileName': 'formula.pdf',
      'mimeType': 'application/pdf',
      'fileSize': 100,
      'status': 'ANALYZING',
      'detectedCategories': [],
      'extractionsByCategory': {},
      'assignments': [],
      'version': 1,
    });

    final patient = model.animalDetails.single;
    expect(patient.name, 'BENJI');
    expect(patient.code, 'AR-B017');
    expect(patient.species, 'Felino');
    expect(patient.breed, 'Persa');
    expect(patient.age, isNull);
    expect(patient.weight, '6 kg');
    expect(model.tutorDetails?.name, 'Andrea Pérez');
    expect(model.tutorDetails?.identification, '123456');
    expect(model.tutorDetails?.phoneNumber, '3001234567');
  });

  test('keeps patient and tutor data nested in additional fields', () {
    final model = MedicalDocumentModel.fromJson({
      'id': 'document-4',
      'animalIds': ['backend-patient'],
      'originalFileName': 'formula.pdf',
      'mimeType': 'application/pdf',
      'fileSize': 100,
      'status': 'ACCEPTED',
      'finalCategory': 'PRESCRIPTION',
      'validatedExtraction': {
        'documentType': 'PRESCRIPTION',
        'patientHints': <String>[],
        'diagnoses': <Object>[],
        'medications': <Object>[],
        'vaccinations': <Object>[],
        'medicalOrders': <Object>[],
        'additionalFields': {
          'patient': {
            'id': 'backend-patient',
            'name': 'BENJI',
            'sex': 'Macho',
            'color': 'Blanco y negro',
            'microchip': '985141000000001',
          },
          'datosPropietario': {
            'nombreCompleto': 'Andrea Pérez',
            'documento': '123456',
            'celular': '3001234567',
            'email': 'andrea@example.com',
          },
        },
        'warnings': <String>[],
      },
      'detectedCategories': <Object>[],
      'extractionsByCategory': <String, Object>{},
      'assignments': <Object>[],
      'version': 2,
    });

    final patient = model.animalDetails.single;
    expect(patient.name, 'BENJI');
    expect(patient.sex, 'Macho');
    expect(patient.color, 'Blanco y negro');
    expect(patient.additionalDetails['microchip'], '985141000000001');
    expect(model.tutorDetails?.name, 'Andrea Pérez');
    expect(model.tutorDetails?.identification, '123456');
    expect(model.tutorDetails?.phoneNumber, '3001234567');
    expect(
      model.tutorDetails?.additionalDetails['email'],
      'andrea@example.com',
    );
  });

  test('finds snake case owner data at arbitrary backend nesting', () {
    final model = MedicalDocumentModel.fromJson({
      'id': 'document-owner-snake-case',
      'animalIds': ['backend-patient'],
      'originalFileName': 'formula.pdf',
      'mimeType': 'application/pdf',
      'fileSize': 100,
      'status': 'REVIEW_PENDING',
      'detectedCategories': <Object>[],
      'extractionsByCategory': {
        'PRESCRIPTION': {
          'documentType': 'PRESCRIPTION',
          'patientHints': <String>[],
          'diagnoses': <Object>[],
          'medications': <Object>[],
          'vaccinations': <Object>[],
          'medicalOrders': <Object>[],
          'additionalFields': {
            'extractedParties': {
              'client_data': {
                'full_name': 'Carlos Gomez',
                'document_number': '998877',
                'phone_number': '3115557788',
                'email': 'carlos@example.com',
              },
            },
          },
          'warnings': <String>[],
        },
      },
      'assignments': <Object>[],
      'version': 1,
    });

    expect(model.tutorDetails?.name, 'Carlos Gomez');
    expect(model.tutorDetails?.identification, '998877');
    expect(model.tutorDetails?.phoneNumber, '3115557788');
    expect(
      model.tutorDetails?.additionalDetails['email'],
      'carlos@example.com',
    );
  });

  test('groups owner label and value rows returned by extraction', () {
    final model = MedicalDocumentModel.fromJson({
      'id': 'document-owner-labels',
      'animalIds': ['backend-patient'],
      'originalFileName': 'formula.pdf',
      'mimeType': 'application/pdf',
      'fileSize': 100,
      'status': 'REVIEW_PENDING',
      'detectedCategories': <Object>[],
      'extractionsByCategory': {
        'PRESCRIPTION': {
          'documentType': 'PRESCRIPTION',
          'patientHints': <String>[],
          'diagnoses': <Object>[],
          'medications': <Object>[],
          'vaccinations': <Object>[],
          'medicalOrders': <Object>[],
          'additionalFields': {
            'ownerInformation': [
              {'label': 'Nombre', 'value': 'Luisa Torres'},
              {'label': 'Documento', 'value': '445566'},
              {'label': 'Celular', 'value': '3004005000'},
              {'label': 'Correo', 'value': 'luisa@example.com'},
            ],
          },
          'warnings': <String>[],
        },
      },
      'assignments': <Object>[],
      'version': 1,
    });

    expect(model.tutorDetails?.name, 'Luisa Torres');
    expect(model.tutorDetails?.identification, '445566');
    expect(model.tutorDetails?.phoneNumber, '3004005000');
    expect(model.tutorDetails?.additionalDetails['email'], 'luisa@example.com');
  });
}
