import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_pdf_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps every medical document category to its export action', () {
    expect(
      medicalDocumentSendActionLabel(MedicalDocumentCategory.prescription),
      'Enviar fórmula',
    );
    expect(
      medicalDocumentSendActionLabel(MedicalDocumentCategory.medicalOrder),
      'Enviar orden',
    );
    expect(
      medicalDocumentSendActionLabel(MedicalDocumentCategory.referral),
      'Enviar remisión',
    );
    expect(
      medicalDocumentSendActionLabel(MedicalDocumentCategory.vaccinationCard),
      'Enviar carné',
    );
    expect(
      medicalDocumentSendActionLabel(MedicalDocumentCategory.clinicalHistory),
      'Enviar historia clínica',
    );
    expect(
      medicalDocumentSendActionLabel(MedicalDocumentCategory.other),
      'Enviar documento',
    );
  });

  test('uses backend patient and veterinarian data', () {
    const extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.prescription,
      summary: 'Tratamiento completo',
      issuer: {
        'name': 'Dra. Natalia López',
        'clinic': 'Clínica Animal Record',
        'professionalId': 'MV-41611',
      },
      diagnoses: [
        MedicalDocumentItemEntity(
          id: 'diagnosis-1',
          fields: {'name': 'Pancreatitis', 'code': 'K85'},
        ),
      ],
      medications: [
        MedicalDocumentItemEntity(
          id: 'medication-1',
          fields: {
            'name': 'Enzymax Holliday',
            'dose': '1/4 tableta',
            'route': 'oral',
            'frequency': 'cada 48 horas',
          },
        ),
      ],
      additionalFields: {'recommendation': 'Control en 15 días'},
      warnings: ['Confirmar peso antes de administrar'],
    );
    const document = MedicalDocumentEntity(
      id: '60366a51-document',
      animalIds: ['backend-animal'],
      animalDetails: [
        MedicalDocumentAnimalEntity(
          id: 'backend-animal',
          name: 'Brownie backend',
          code: 'AR-BACK',
          species: 'CANINE',
          breed: 'Labrador',
          age: '8 años',
          weight: '18 kg',
        ),
      ],
      originalFileName: 'Fórmula médica.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.reviewPending,
      version: 1,
    );

    final analysis = medicalDocumentToAnalysis(
      document: document,
      extraction: extraction,
    );

    expect(analysis.patient.name, 'Brownie backend');
    expect(analysis.patient.recordId, 'AR-BACK');
    expect(analysis.patient.species, 'CANINE');
    expect(analysis.patient.breed, 'Labrador');
    expect(analysis.patient.age, '8 años');
    expect(analysis.patient.weight, '18 kg');
    expect(analysis.veterinarian?.name, 'Dra. Natalia López');
    expect(analysis.veterinarian?.clinic, 'Clínica Animal Record');
    expect(analysis.veterinarian?.professionalId, 'MV-41611');
    expect(analysis.itemsTitle, 'Medicamentos');
    expect(analysis.medications.single.name, 'Enzymax Holliday');
    expect(analysis.medications.single.instructions, contains('1/4 tableta'));
    expect(analysis.medications.single.instructions, contains('cada 48 horas'));
    expect(analysis.observations, contains('Pancreatitis'));
    expect(analysis.observations, contains('Control en 15 días'));
    expect(analysis.observations, contains('Confirmar peso'));
  });

  test('uses backend patient hints without inventing missing fields', () {
    const extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.prescription,
      patientHints: [
        'BENJI',
        'CANINE',
        'Samoyedo',
        'Macho',
        'Blanco y negro',
        '2.5 Kilogramos',
        '0 años, 5 meses y 20 días',
      ],
    );
    const document = MedicalDocumentEntity(
      id: 'document-hints',
      animalIds: ['backend-animal'],
      originalFileName: 'formula.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.reviewPending,
      version: 1,
    );

    final analysis = medicalDocumentToAnalysis(
      document: document,
      extraction: extraction,
    );

    expect(analysis.patient.name, 'BENJI');
    expect(analysis.patient.species, 'CANINE');
    expect(analysis.patient.breed, 'Samoyedo');
    expect(analysis.patient.sex, 'Macho');
    expect(analysis.patient.color, 'Blanco y negro');
    expect(analysis.patient.recordId, isEmpty);
    expect(analysis.patient.age, '0 años, 5 meses y 20 días');
    expect(analysis.patient.weight, '2.5 Kilogramos');
    expect(analysis.date, isNull);
    expect(analysis.tutor.hasData, isFalse);
    expect(analysis.veterinarian, isNull);
    expect(analysis.observations, isNull);
  });

  test('keeps non-empty backend values and discards empty collections', () {
    const extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.prescription,
      medications: [
        MedicalDocumentItemEntity(
          id: 'medication-value',
          fields: {
            'quantity': 'una caja',
            'instructions': 'Administrar según indicación',
          },
        ),
        MedicalDocumentItemEntity(
          id: 'medication-empty',
          fields: {'name': '', 'recommendations': <String>[]},
        ),
      ],
    );
    const document = MedicalDocumentEntity(
      id: 'document-values',
      animalIds: ['backend-animal'],
      originalFileName: 'formula.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.reviewPending,
      version: 1,
    );

    final analysis = medicalDocumentToAnalysis(
      document: document,
      extraction: extraction,
    );

    expect(analysis.medications, hasLength(1));
    expect(analysis.medications.single.quantity, isNull);
    expect(analysis.medications.single.instructions, contains('una caja'));
    expect(
      analysis.medications.single.instructions,
      contains('Administrar según indicación'),
    );
    expect(
      analysis.medications.single.instructions,
      'Cantidad: una caja\nIndicaciones: Administrar según indicación',
    );
  });

  test('places each medication field on a separate line', () {
    const extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.prescription,
      medications: [
        MedicalDocumentItemEntity(
          id: 'medication-lines',
          fields: {
            'name': 'Medicamento',
            'presentation': 'Suspensión',
            'dose': '0,3 ml',
            'route': 'oral',
            'frequency': 'cada 24 horas',
            'duration': '15 días',
          },
        ),
      ],
    );
    const document = MedicalDocumentEntity(
      id: 'document-lines',
      animalIds: ['backend-animal'],
      originalFileName: 'formula.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.reviewPending,
      version: 1,
    );

    final analysis = medicalDocumentToAnalysis(
      document: document,
      extraction: extraction,
    );

    expect(
      analysis.medications.single.instructions,
      'Presentación: Suspensión\n'
      'Dosis: 0,3 ml\n'
      'Vía: oral\n'
      'Frecuencia: cada 24 horas\n'
      'Duración: 15 días',
    );
  });

  test('keeps and parses the localized document date from backend', () {
    const extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.prescription,
      documentDate: 'miércoles, 14 de mayo de 2025, 7:21 p.m.',
    );
    const document = MedicalDocumentEntity(
      id: 'document-date',
      animalIds: ['backend-animal'],
      originalFileName: 'formula.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.reviewPending,
      version: 1,
    );

    final analysis = medicalDocumentToAnalysis(
      document: document,
      extraction: extraction,
    );

    expect(analysis.date, DateTime(2025, 5, 14, 19, 21));
    expect(analysis.sourceDateText, 'miércoles, 14 de mayo de 2025, 7:21 p.m.');
  });
}
