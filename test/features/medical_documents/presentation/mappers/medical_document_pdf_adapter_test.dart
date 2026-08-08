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
      summary: 'Tratamiento completo. Control posterior.',
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
      warnings: ['Confirmar peso antes de administrar. Mantener refrigerado.'],
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
    expect(analysis.itemsTitle, 'Medications');
    expect(analysis.medications.single.name, 'Enzymax Holliday');
    expect(analysis.medications.single.instructions, contains('1/4 tableta'));
    expect(analysis.medications.single.instructions, contains('cada 48 horas'));
    expect(
      analysis.sections
          .firstWhere((section) => section.title == 'Diagnoses')
          .details
          .firstWhere((detail) => detail.label == 'Name')
          .value,
      'Pancreatitis',
    );
    expect(
      analysis.sections
          .firstWhere((section) => section.title == 'Información adicional')
          .details
          .firstWhere((detail) => detail.label == 'Recommendation')
          .value,
      'Control en 15 días',
    );
    expect(
      analysis.sections
          .firstWhere((section) => section.title == 'Información adicional')
          .body,
      'Tratamiento completo.\nControl posterior.\n'
      'Confirmar peso antes de administrar.\nMantener refrigerado.',
    );
    expect(analysis.observations, isNull);
  });

  test('keeps referral backend objects in separate structured sections', () {
    const extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.referral,
      summary: 'Remisión para valoración especializada',
      referral: {
        'reason': 'Evaluación cardiológica',
        'destination': 'Dr. Alejandro Torres',
        'specialty': 'Cardiología Veterinaria',
        'clinicalSummary': 'Paciente con soplo grado III/VI',
        'confidence': 0.94,
        'source': {'page': 1},
      },
      additionalFields: {
        'current_treatment_summary': 'Sin tratamiento cardíaco previo',
        'studies_performed': 'Hemograma y radiografía de tórax',
        'referral_number': '001-2024',
        'referral': {'reason': 'No debe duplicarse'},
      },
    );
    const document = MedicalDocumentEntity(
      id: 'referral-document',
      animalIds: ['animal-1'],
      originalFileName: 'remision.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.reviewPending,
      version: 1,
    );

    final analysis = medicalDocumentToAnalysis(
      document: document,
      extraction: extraction,
    );

    final referral = analysis.sections.singleWhere(
      (section) => section.title == 'Referral',
    );
    expect(referral.details.map((detail) => detail.label), [
      'Reason',
      'Destination',
      'Specialty',
      'Clinical Summary',
    ]);
    expect(referral.details.map((detail) => detail.value), [
      'Evaluación cardiológica',
      'Dr. Alejandro Torres',
      'Cardiología Veterinaria',
      'Paciente con soplo grado III/VI',
    ]);

    final additional = analysis.sections.singleWhere(
      (section) => section.title == 'Información adicional',
    );
    expect(additional.details.map((detail) => detail.label), [
      'Current treatment summary',
      'Studies performed',
      'Referral number',
    ]);
    expect(additional.body, 'Remisión para valoración especializada');
    expect(analysis.observations, isNull);
  });

  test('does not infer patient fields from positional hints', () {
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

    expect(analysis.patient.hasData, isFalse);
    expect(analysis.date, isNull);
    expect(analysis.tutor.hasData, isFalse);
    expect(analysis.veterinarian, isNull);
    expect(analysis.observations, isNull);
  });

  test('renders patient key-value fields exactly as received', () {
    const extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.clinicalHistory,
    );
    const document = MedicalDocumentEntity(
      id: 'document-labeled-patient',
      animalIds: ['backend-animal'],
      animalDetails: [
        MedicalDocumentAnimalEntity(
          id: 'backend-animal',
          name: 'Panchita',
          fields: {
            'Name': 'Panchita',
            'Species': 'Canine',
            'Breed': 'Chihuahua',
            'Gender': 'Female (Spayed)',
            'Description': 'Brown/white',
            'Date of Birth': '1/24/2023',
            'Weight': '7.60 Lbs',
          },
        ),
      ],
      originalFileName: 'historia.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.reviewPending,
      version: 1,
    );

    final analysis = medicalDocumentToAnalysis(
      document: document,
      extraction: extraction,
    );

    expect(analysis.patient.name, 'Panchita');
    expect(analysis.patient.recordId, isEmpty);
    expect(analysis.patient.species, isEmpty);
    expect(
      analysis.patient.additionalDetails.map(
        (detail) => (detail.label, detail.value),
      ),
      [
        ('Species', 'Canine'),
        ('Breed', 'Chihuahua'),
        ('Gender', 'Female (Spayed)'),
        ('Description', 'Brown/white'),
        ('Date of Birth', '1/24/2023'),
        ('Weight', '7.60 Lbs'),
      ],
    );
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
      'Quantity: una caja\nInstructions: Administrar según indicación',
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
      'Presentation: Suspensión\n'
      'Dose: 0,3 ml\n'
      'Route: oral\n'
      'Frequency: cada 24 horas\n'
      'Duration: 15 días',
    );
  });

  test('keeps vaccine keys and values unchanged in aligned details', () {
    const extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.vaccinationCard,
      vaccinations: [
        MedicalDocumentItemEntity(
          id: 'vaccine-1',
          fields: {
            'name': 'Rabies',
            'diseasesCovered': ['Rabies'],
            'manufacturer': 'Zoetis Vanguard',
            'vaccineType': 'Killed',
            'lotExpirationDate': '7/18/2026',
          },
        ),
      ],
    );
    const document = MedicalDocumentEntity(
      id: 'vaccination-document',
      animalIds: ['animal-1'],
      originalFileName: 'vaccination.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.reviewPending,
      version: 1,
    );

    final analysis = medicalDocumentToAnalysis(
      document: document,
      extraction: extraction,
    );
    final vaccine = analysis.medications.single;

    expect(vaccine.name, 'Rabies');
    expect(vaccine.instructions, isEmpty);
    expect(vaccine.details.map((detail) => detail.label), [
      'Diseases Covered',
      'Manufacturer',
      'Vaccine Type',
      'Lot Expiration Date',
    ]);
    expect(vaccine.details.map((detail) => detail.value), [
      'Rabies',
      'Zoetis Vanguard',
      'Killed',
      '7/18/2026',
    ]);
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
