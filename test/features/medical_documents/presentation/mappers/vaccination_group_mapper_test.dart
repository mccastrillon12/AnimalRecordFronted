import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/vaccination_group_mapper.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groups equivalent vaccine names in English and Spanish', () {
    final documents = [
      _document(
        id: 'english-rabies',
        vaccination: const MedicalDocumentItemEntity(
          id: 'rabies-1',
          fields: {
            'name': 'Rabies',
            'applicationDate': 'June 10, 2024',
            'nextDoseDate': 'June 10, 2025',
          },
        ),
      ),
      _document(
        id: 'spanish-rabies',
        vaccination: const MedicalDocumentItemEntity(
          id: 'rabies-2',
          fields: {
            'name': 'Rabia',
            'fechaDeAplicacion': '10/27/2025',
            'proximaDosis': '10/27/2028',
          },
        ),
      ),
    ];

    final groups = groupVaccinations(documents);

    expect(groups, hasLength(1));
    expect(groups.single.key, 'rabies');
    expect(groups.single.title, 'Rabia');
    expect(groups.single.count, 2);
    expect(groups.single.latest.sourceName, 'Rabia');
    expect(groups.single.latest.applicationDate, '10/27/2025');
    expect(groups.single.latest.applicationDateLabel, 'Fecha De Aplicacion');
    expect(groups.single.latest.nextDoseDate, '10/27/2028');
    expect(groups.single.latest.nextDoseDateLabel, 'Proxima Dosis');
  });

  test(
    'uses covered diseases to group product names without translating them',
    () {
      final documents = [
        _document(
          id: 'product-name',
          vaccination: const MedicalDocumentItemEntity(
            id: 'distemper-1',
            fields: {
              'name': 'Vanguard Product',
              'diseasesCovered': ['Canine Distemper'],
            },
          ),
        ),
        _document(
          id: 'spanish-name',
          vaccination: const MedicalDocumentItemEntity(
            id: 'distemper-2',
            fields: {'nombre': 'Moquillo canino'},
          ),
        ),
      ];

      final groups = groupVaccinations(documents);

      expect(groups, hasLength(1));
      expect(groups.single.key, 'distemper');
      expect(groups.single.title, 'Vanguard Product');
      expect(groups.single.count, 2);
    },
  );

  test('sorts two-digit vaccination dates from newest to oldest', () {
    final documents = [
      _document(
        id: 'rabies-2022',
        vaccination: const MedicalDocumentItemEntity(
          id: 'rabies-2022-item',
          fields: {
            'name': 'Rabia',
            'applicationDate': '7/01/22',
            'nextDoseDate': '7/01/23',
          },
        ),
      ),
      _document(
        id: 'rabies-2025',
        vaccination: const MedicalDocumentItemEntity(
          id: 'rabies-2025-item',
          fields: {
            'name': 'Rabies',
            'applicationDate': '7/01/25',
            'nextDoseDate': '7/01/26',
          },
        ),
      ),
      _document(
        id: 'rabies-2023',
        vaccination: const MedicalDocumentItemEntity(
          id: 'rabies-2023-item',
          fields: {
            'name': 'Rabia',
            'applicationDate': '7/01/23',
            'nextDoseDate': '7/01/24',
          },
        ),
      ),
      _document(
        id: 'rabies-2024',
        vaccination: const MedicalDocumentItemEntity(
          id: 'rabies-2024-item',
          fields: {
            'name': 'Rabia',
            'applicationDate': '7/01/24',
            'nextDoseDate': '7/01/25',
          },
        ),
      ),
    ];

    final group = groupVaccinations(documents).single;

    expect(group.applications.map((item) => item.document.id), [
      'rabies-2025',
      'rabies-2024',
      'rabies-2023',
      'rabies-2022',
    ]);
    expect(group.latest.applicationDate, '7/01/25');
    expect(group.latest.nextDoseDate, '7/01/26');
  });

  test('builds ordered doses and preserves parties and original links', () {
    final documents = [
      _document(
        id: 'rabies-old',
        vaccination: const MedicalDocumentItemEntity(
          id: 'rabies-1',
          fields: {
            'name': 'Rabies',
            'applicationDate': 'June 10, 2024',
            'brand': 'Virbac',
            'manufacturer': 'Medicine Lab',
            'lotNumber': '0000A1',
          },
        ),
        issuer: const {
          'name': 'Juanita Doe',
          'clinic': 'Veterinaria Central',
          'professionalId': 'TP-1',
        },
        patient: const MedicalDocumentPatientEntity(
          name: 'Max',
          identifier: 'AR-MAX',
          species: 'Canino',
        ),
        owner: const MedicalDocumentOwnerEntity(
          name: 'John Doe',
          identification: 'C.C. 4567',
        ),
      ),
      _document(
        id: 'rabies-new',
        vaccination: const MedicalDocumentItemEntity(
          id: 'rabies-2',
          fields: {
            'name': 'Rabia',
            'applicationDate': '10/27/2025',
            'nextDoseDate': '10/27/2028',
            'applicationSite': 'M- pélvico izquierdo',
          },
        ),
        issuer: const {'name': 'María Ríos', 'professionalId': 'TP-2'},
        patient: const MedicalDocumentPatientEntity(
          name: 'Brownie',
          identifier: 'AR-C012',
          species: 'Canino',
        ),
        owner: const MedicalDocumentOwnerEntity(
          name: 'Barbara James',
          identification: 'C.C. 1152234567',
          phone: '312 456 78 90',
        ),
      ),
    ];

    final group = groupVaccinations(documents).single;
    final detail = vaccinationDetailViewData(group);
    final pdf = vaccinationGroupToPdfAnalysis(
      group,
      originalUrls: const {
        'rabies-old': 'https://example.test/rabies-old.pdf',
        'rabies-new': 'https://example.test/rabies-new.pdf',
      },
    );

    expect(detail.vaccineName, 'Rabia');
    expect(detail.doses.map((dose) => dose.title), ['Dosis 1', 'Dosis 2']);
    expect(detail.doses.first.document.id, 'rabies-new');
    expect(detail.doses.first.nextDoseDate, '10/27/2028');
    expect(detail.doses.first.veterinarian?.name, 'María Ríos');
    expect(detail.doses.last.veterinarian?.name, 'Juanita Doe');
    expect(detail.doses.first.tutor.name, 'Barbara James');
    expect(detail.doses.first.patient.name, 'Brownie');
    expect(detail.doses.last.tutor.name, 'John Doe');
    expect(detail.doses.last.patient.name, 'Max');
    expect(
      detail.doses.last.details.map((detail) => detail.label),
      containsAllInOrder([
        'Application Date',
        'Brand',
        'Manufacturer',
        'Lot Number',
      ]),
    );
    expect(pdf.documentType, 'Carné de vacunación');
    expect(pdf.itemsTitle, 'Vacuna Rabia');
    expect(pdf.medications, hasLength(2));
    expect(pdf.medications.map((dose) => dose.originalUrl), [
      'https://example.test/rabies-new.pdf',
      'https://example.test/rabies-old.pdf',
    ]);
    expect(pdf.sections, isEmpty);
    expect(
      pdf.medications.first.details,
      containsAll([
        const SharedFileAnalysisDetailEntity(
          label: 'Next Dose Date',
          value: '10/27/2028',
        ),
        const SharedFileAnalysisDetailEntity(
          label: 'Tutor',
          value: 'Barbara James',
        ),
        const SharedFileAnalysisDetailEntity(
          label: 'Paciente',
          value: 'Brownie',
        ),
      ]),
    );
    expect(
      pdf.medications.last.details,
      containsAll([
        const SharedFileAnalysisDetailEntity(label: 'Tutor', value: 'John Doe'),
        const SharedFileAnalysisDetailEntity(label: 'Paciente', value: 'Max'),
      ]),
    );
  });

  test('maps a carnet by vaccine type and keeps every related dose', () {
    final groups = groupVaccinations([
      _document(
        id: 'rabies-old',
        vaccination: const MedicalDocumentItemEntity(
          id: 'rabies-1',
          fields: {'name': 'Rabies', 'applicationDate': '6/10/2024'},
        ),
      ),
      _document(
        id: 'rabies-new',
        vaccination: const MedicalDocumentItemEntity(
          id: 'rabies-2',
          fields: {'name': 'Rabia', 'applicationDate': '10/27/2025'},
        ),
      ),
      _document(
        id: 'parvo',
        vaccination: const MedicalDocumentItemEntity(
          id: 'parvo-1',
          fields: {'name': 'Parvovirus', 'applicationDate': '5/1/2025'},
        ),
      ),
    ]);
    const patient = SharedFilePatientAnalysisEntity(
      name: 'Brownie',
      recordId: 'AR-C012',
      species: 'Canino',
      breed: 'Labrador',
      age: '10 años',
      weight: '15 kg',
    );
    const tutor = SharedFileTutorAnalysisEntity(
      name: 'Barbara James',
      identification: 'C.C. 1152234567',
      phoneNumber: '3124567890',
    );

    final carnet = vaccinationGroupsToPdfAnalysis(
      groups,
      documentType: 'Carné de vacunación',
      patient: patient,
      tutor: tutor,
    );
    final rabies = groups.singleWhere((group) => group.key == 'rabies');
    final certificate = vaccinationGroupsToPdfAnalysis(
      [rabies],
      documentType: 'Certificado de vacunación',
      patient: patient,
      tutor: tutor,
    );

    expect(carnet.patient, patient);
    expect(carnet.tutor, tutor);
    expect(carnet.medications, hasLength(3));
    expect(carnet.medications.map((dose) => dose.groupTitle), [
      'Vacuna Rabia',
      'Vacuna Rabia',
      'Vacuna Parvovirus',
    ]);
    expect(certificate.documentType, 'Certificado de vacunación');
    expect(certificate.medications, hasLength(2));
    expect(certificate.medications.map((dose) => dose.groupTitle).toSet(), {
      'Vacuna Rabia',
    });
  });
}

MedicalDocumentEntity _document({
  required String id,
  required MedicalDocumentItemEntity vaccination,
  Map<String, dynamic>? issuer,
  MedicalDocumentPatientEntity? patient,
  MedicalDocumentOwnerEntity? owner,
}) {
  return MedicalDocumentEntity(
    id: id,
    animalIds: const ['animal-1'],
    originalFileName: '$id.pdf',
    mimeType: 'application/pdf',
    fileSize: 100,
    status: MedicalDocumentStatus.accepted,
    finalCategory: MedicalDocumentCategory.vaccinationCard,
    validatedExtraction: MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.vaccinationCard,
      issuer: issuer,
      patient: patient,
      owner: owner,
      vaccinations: [vaccination],
    ),
    version: 1,
  );
}
