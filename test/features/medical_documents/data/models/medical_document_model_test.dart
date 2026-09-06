import 'package:animal_record/features/medical_documents/data/models/medical_document_model.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves unknown extraction properties during serialization', () {
    const unknownValue = {
      'futureMetadata': {'reviewed': false, 'sequence': 0},
    };
    final extraction = MedicalDocumentModel.extractionFromJson({
      'documentType': 'CLINICAL_HISTORY',
      ...unknownValue,
      'additionalFields': <String, dynamic>{},
    }, MedicalDocumentCategory.clinicalHistory);

    expect(extraction.preservedUnknownFields, unknownValue);
    expect(
      MedicalDocumentModel.extractionToJson(extraction)['futureMetadata'],
      unknownValue['futureMetadata'],
    );
  });

  test('override sends every raw backend value except confidence metadata', () {
    final extraction = MedicalDocumentModel.extractionFromJson({
      'documentType': 'VACCINATION_CARD',
      'documentTypeConfidence': 0.91,
      'patient': {
        'name': 'Chuleta',
        'measurements': {'weight': 12.4, 'verified': true},
      },
      'owner': {
        'name': 'Maria',
        'preferredContact': {'channel': 'WHATSAPP', 'enabled': true},
      },
      'vaccinations': [
        {
          'id': 'vaccination-1',
          'name': 'Rabia',
          'confidence': 0.82,
          'source': {
            'page': 1,
            'text': 'Rabies',
            'boundingBox': [1, 2, 3, 4],
          },
          'futureDetails': {
            'lotVerified': true,
            'temperatures': [2.5, 3.0],
          },
        },
      ],
      'futureSection': {
        'classificationScore': 0.72,
        'medicalValue': 'Conservar',
      },
      'additionalFields': <String, dynamic>{},
    }, MedicalDocumentCategory.vaccinationCard);

    final payload = MedicalDocumentModel.reviewRequestToJson(
      ReviewMedicalDocumentRequest.accept(
        documentVersion: 2,
        finalCategory: MedicalDocumentCategory.prescription,
        validatedExtraction: extraction,
        assignments: const [
          MedicalDocumentAssignmentEntity(
            animalId: 'animal-1',
            extractedItemIds: ['vaccination-1'],
          ),
        ],
      ),
    );
    final validated = payload['validatedExtraction'] as Map<String, dynamic>;
    final vaccination =
        (validated['vaccinations'] as List).single as Map<String, dynamic>;

    expect(validated['documentType'], 'VACCINATION_CARD');
    expect(validated, isNot(contains('documentTypeConfidence')));
    expect((validated['patient'] as Map)['measurements'], {
      'weight': 12.4,
      'verified': true,
    });
    expect((validated['owner'] as Map)['preferredContact'], {
      'channel': 'WHATSAPP',
      'enabled': true,
    });
    expect(vaccination['id'], 'vaccination-1');
    expect(vaccination, isNot(contains('confidence')));
    expect((vaccination['source'] as Map)['boundingBox'], [1, 2, 3, 4]);
    expect((vaccination['futureDetails'] as Map)['temperatures'], [2.5, 3.0]);
    expect(validated['futureSection'], {'medicalValue': 'Conservar'});
  });

  test('matching category keeps the existing typed serialization', () {
    final extraction = MedicalDocumentModel.extractionFromJson({
      'documentType': 'PRESCRIPTION',
      'documentTypeConfidence': 0.91,
      'futureNestedOwner': {'value': true},
      'additionalFields': <String, dynamic>{},
    }, MedicalDocumentCategory.prescription);

    final payload = MedicalDocumentModel.reviewRequestToJson(
      ReviewMedicalDocumentRequest.accept(
        documentVersion: 2,
        finalCategory: MedicalDocumentCategory.prescription,
        validatedExtraction: extraction,
        assignments: const [
          MedicalDocumentAssignmentEntity(animalId: 'animal-1'),
        ],
      ),
    );
    final validated = payload['validatedExtraction'] as Map<String, dynamic>;

    expect(validated['documentTypeConfidence'], 0.91);
    expect(validated['futureNestedOwner'], {'value': true});
  });

  test('supports the diagnostic image and laboratory result categories', () {
    expect(
      MedicalDocumentCategory.tryParse('DIAGNOSTIC_IMAGE'),
      MedicalDocumentCategory.diagnosticImage,
    );
    expect(
      MedicalDocumentCategory.tryParse('LABORATORY_RESULT'),
      MedicalDocumentCategory.laboratoryResult,
    );
    expect(
      MedicalDocumentCategory.diagnosticImage.wireValue,
      'DIAGNOSTIC_IMAGE',
    );
    expect(
      MedicalDocumentCategory.laboratoryResult.wireValue,
      'LABORATORY_RESULT',
    );
  });

  test('keeps only laboratory results when that category is selected', () {
    const result = MedicalDocumentItemEntity(
      id: 'result-1',
      fields: {'name': 'Hemograma', 'result': '15', 'flag': '*'},
    );
    const extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.laboratoryResult,
      laboratoryResults: [result],
    );

    final sanitized = extraction.sanitizedFor(
      MedicalDocumentCategory.laboratoryResult,
    );

    expect(sanitized.documentType, MedicalDocumentCategory.laboratoryResult);
    expect(sanitized.diagnosticResults, isEmpty);
    expect(sanitized.laboratoryResults, const [result]);
  });

  test(
    'parses and serializes diagnostic images and laboratory fields verbatim',
    () {
      final model = MedicalDocumentModel.fromJson({
        'id': 'laboratory-document',
        'animalIds': ['animal-1'],
        'originalFileName': 'laboratorio.pdf',
        'mimeType': 'application/pdf',
        'fileSize': 100,
        'status': 'REVIEW_PENDING',
        'extractionsByCategory': {
          'LABORATORY_RESULT': {
            'documentType': 'LABORATORY_RESULT',
            'laboratoryReport': {
              'orderNumber': '21010685',
              'reportedComments': ['* Resultado confirmado'],
            },
            'laboratoryResults': [
              {
                'id': 'laboratory-result-1',
                'panel': 'QUIMICA SANGUINEA',
                'name': 'Urea',
                'result': '15',
                'unit': 'mg/dl',
                'referenceRange': '24,0 60,0',
                'flag': '*',
              },
            ],
          },
          'DIAGNOSTIC_IMAGE': {
            'documentType': 'DIAGNOSTIC_IMAGE',
            'diagnosticImages': [
              {
                'id': 'image-1',
                'name': 'Radiografía lateral',
                'modality': 'RX',
              },
            ],
          },
        },
        'detectedCategories': [],
        'assignments': [],
        'version': 1,
      });

      final laboratory = model
          .extractionsByCategory[MedicalDocumentCategory.laboratoryResult]!;
      expect(laboratory.laboratoryReport?['reportedComments'], [
        '* Resultado confirmado',
      ]);
      expect(laboratory.laboratoryResults.single.fields['flag'], '*');
      expect(
        laboratory.laboratoryResults.single.fields['referenceRange'],
        '24,0 60,0',
      );
      expect(
        model
            .extractionsByCategory[MedicalDocumentCategory.diagnosticImage]
            ?.diagnosticImages
            .single
            .fields['modality'],
        'RX',
      );

      final payload = MedicalDocumentModel.extractionToJson(laboratory);
      expect((payload['laboratoryResults'] as List).single['result'], '15');
      expect((payload['laboratoryResults'] as List).single['flag'], '*');
    },
  );

  test('parses the complete backend response without losing category data', () {
    final model = MedicalDocumentModel.fromJson({
      'id': 'document-1',
      'documentCode': '57-001',
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
          'patient': {
            'name': 'Brownie',
            'identifier': 'AR-001',
            'species': 'Canino',
            'breed': 'Labrador',
            'microchip': '985141000000001',
          },
          'owner': {
            'name': 'Barbara James',
            'identification': '1152234567',
            'phone': '3124567890',
            'email': 'barbara@example.com',
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
    expect(model.documentCode, '57-001');
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
    expect(extraction.patient?.identifier, 'AR-001');
    expect(extraction.patient?.microchip, '985141000000001');
    expect(extraction.owner?.name, 'Barbara James');
    expect(extraction.owner?.email, 'barbara@example.com');
    expect(extraction.additionalFields['clinic'], 'Animal Record');
    expect(model.version, 3);
  });

  test(
    'serializes an accepted review with exactly one assignment per animal',
    () {
      const extraction = MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.prescription,
        patient: MedicalDocumentPatientEntity(
          name: 'Brownie',
          identifier: 'AR-001',
        ),
        owner: MedicalDocumentOwnerEntity(
          name: 'Barbara James',
          phone: '3124567890',
        ),
        patientHints: ['Brownie'],
        medications: [
          MedicalDocumentItemEntity(
            id: 'medication-1',
            confidence: 0.869140625,
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
      expect(validated['patient'], {'name': 'Brownie', 'identifier': 'AR-001'});
      expect(validated['owner'], {
        'name': 'Barbara James',
        'phone': '3124567890',
      });
      expect(validated['diagnoses'], isEmpty);
      expect(validated['vaccinations'], isEmpty);
      expect(validated, containsPair('warnings', isEmpty));
      expect(
        (validated['medications'] as List).single,
        containsPair('confidence', 0.869140625),
      );
      expect((payload['assignments'] as List), hasLength(2));
      expect(
        (payload['assignments'] as List).last['extractedItemIds'],
        isEmpty,
      );
    },
  );

  test('serializes a rejected review with its selected reason', () {
    final payload = MedicalDocumentModel.reviewRequestToJson(
      ReviewMedicalDocumentRequest.reject(
        documentVersion: 5,
        rejectionReasonCode: 'OTHER',
        rejectionComment: 'La imagen está borrosa',
      ),
    );

    expect(payload, {
      'decision': 'REJECT',
      'documentVersion': 5,
      'rejectionReason': 'OTHER',
      'rejectionComment': 'La imagen está borrosa',
    });
  });

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

  test('preserves patient hints without treating them as patient fields', () {
    final model = MedicalDocumentModel.fromJson({
      'id': 'document-patient-key-value',
      'animalIds': ['backend-patient'],
      'originalFileName': 'historia.pdf',
      'mimeType': 'application/pdf',
      'fileSize': 100,
      'status': 'REVIEW_PENDING',
      'detectedCategories': <Object>[],
      'extractionsByCategory': {
        'CLINICAL_HISTORY': {
          'documentType': 'CLINICAL_HISTORY',
          'patientHints': [
            'Name: Panchita',
            'Species: Canine',
            'Breed: Chihuahua',
            'Gender: Female (Spayed)',
            'Description: Brown/white',
            'Date of Birth: 1/24/2023',
            'Weight: 7.60 Lbs',
          ],
          'additionalFields': <String, Object>{},
        },
      },
      'assignments': <Object>[],
      'version': 1,
    });

    expect(model.animalDetails, isEmpty);
    final extraction =
        model.extractionsByCategory[MedicalDocumentCategory.clinicalHistory]!;
    expect(extraction.patient, isNull);
    expect(extraction.patientHints, [
      'Name: Panchita',
      'Species: Canine',
      'Breed: Chihuahua',
      'Gender: Female (Spayed)',
      'Description: Brown/white',
      'Date of Birth: 1/24/2023',
      'Weight: 7.60 Lbs',
    ]);
  });

  test('does not promote additional tutor hints to structured owner', () {
    final model = MedicalDocumentModel.fromJson({
      'id': 'document-tutor-key-value',
      'animalIds': ['animal-1'],
      'originalFileName': 'historia.pdf',
      'mimeType': 'application/pdf',
      'fileSize': 100,
      'status': 'REVIEW_PENDING',
      'detectedCategories': <Object>[],
      'extractionsByCategory': {
        'CLINICAL_HISTORY': {
          'documentType': 'CLINICAL_HISTORY',
          'additionalFields': {
            'tutorHints': [
              'Name: Maria Perez',
              'Phone: 3001234567',
              'Address: Main Street 42',
            ],
          },
        },
      },
      'assignments': <Object>[],
      'version': 1,
    });

    expect(model.tutorDetails, isNull);
    final extraction =
        model.extractionsByCategory[MedicalDocumentCategory.clinicalHistory]!;
    expect(extraction.owner, isNull);
    expect(extraction.additionalFields['tutorHints'], isNotEmpty);
  });

  test('uses structured patient and owner from validated extraction', () {
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
        'patient': {
          'identifier': 'backend-patient',
          'name': 'BENJI',
          'sex': 'Macho',
          'color': 'Blanco y negro',
          'microchip': '985141000000001',
        },
        'owner': {
          'name': 'Andrea Pérez',
          'identification': '123456',
          'phone': '3001234567',
          'email': 'andrea@example.com',
        },
        'patientHints': <String>[],
        'diagnoses': <Object>[],
        'medications': <Object>[],
        'vaccinations': <Object>[],
        'medicalOrders': <Object>[],
        'additionalFields': <String, Object>{},
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
    expect(model.validatedExtraction?.patient?.name, 'BENJI');
    expect(model.validatedExtraction?.patient?.fields, {
      'identifier': 'backend-patient',
      'name': 'BENJI',
      'sex': 'Macho',
      'color': 'Blanco y negro',
      'microchip': '985141000000001',
    });
    expect(model.tutorDetails?.name, 'Andrea Pérez');
    expect(model.tutorDetails?.identification, '123456');
    expect(model.tutorDetails?.phoneNumber, '3001234567');
    expect(
      model.tutorDetails?.additionalDetails['email'],
      'andrea@example.com',
    );
    expect(model.validatedExtraction?.owner?.name, 'Andrea Pérez');
  });

  test('does not infer owner from arbitrary additional-field nesting', () {
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

    expect(model.tutorDetails, isNull);
    expect(
      model
          .extractionsByCategory[MedicalDocumentCategory.prescription]
          ?.additionalFields['extractedParties'],
      isNotNull,
    );
  });

  test('does not infer owner from label-value rows in additional fields', () {
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

    expect(model.tutorDetails, isNull);
  });
}
