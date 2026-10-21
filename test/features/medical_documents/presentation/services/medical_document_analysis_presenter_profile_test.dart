import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_field_catalog.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/services/medical_document_analysis_presenter.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetMedicalFieldCatalogUseCase extends Mock
    implements GetMedicalFieldCatalogUseCase {}

void main() {
  late _MockGetMedicalFieldCatalogUseCase getCatalog;
  late MedicalDocumentAnalysisPresenter presenter;

  setUpAll(() {
    registerFallbackValue(MedicalDocumentCategory.prescription);
  });

  setUp(() {
    getCatalog = _MockGetMedicalFieldCatalogUseCase();
    when(
      () => getCatalog(category: any(named: 'category')),
    ).thenAnswer((_) async => _catalog);
    presenter = MedicalDocumentAnalysisPresenter(getFieldCatalog: getCatalog);
  });

  test(
    'keeps extracted display data and uses the app profile only for the PDF',
    () async {
      final analysis = await presenter.forAccepted(
        _document(weight: '8.4 kg'),
        appPatient: _appPatient(weight: '15 kg'),
        appTutor: _appTutor,
      );

      expect(analysis.patient.name, 'Paciente extraído');
      expect(analysis.tutor.name, 'Tutor extraído');
      expect(analysis.veterinarian?.name, 'Veterinaria extraída');
      expect(analysis.pdfPatient?.name, 'Eithan');
      expect(analysis.pdfPatient?.recordId, 'AR-C049');
      expect(analysis.pdfPatient?.species, 'Canino');
      expect(analysis.pdfPatient?.breed, 'Criollo');
      expect(analysis.pdfPatient?.sex, 'Macho');
      expect(analysis.pdfPatient?.age, '7-11 meses');
      expect(analysis.pdfPatient?.weight, '8.4 kg');
      expect(analysis.pdfTutor, _appTutor);
      expect(analysis.originalMimeType, 'image/jpeg');
    },
  );

  test(
    'falls back to app weight and omits it when both sources lack it',
    () async {
      final appWeight = await presenter.forAccepted(
        _document(),
        appPatient: _appPatient(weight: '15 kg'),
        appTutor: _appTutor,
      );
      final noWeight = await presenter.forAccepted(
        _document(),
        appPatient: _appPatient(weight: ''),
        appTutor: _appTutor,
      );

      expect(appWeight.pdfPatient?.weight, '15 kg');
      expect(noWeight.pdfPatient?.weight, isEmpty);
    },
  );
}

MedicalDocumentEntity _document({String? weight}) {
  return MedicalDocumentEntity(
    id: 'document-1',
    documentCode: 'F-57-11230',
    animalIds: const ['animal-1'],
    originalFileName: 'formula.jpg',
    mimeType: 'image/jpeg',
    fileSize: 100,
    status: MedicalDocumentStatus.accepted,
    validatedExtraction: MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.prescription,
      patient: MedicalDocumentPatientEntity(
        name: 'Paciente extraído',
        identifier: 'DOC-1',
        species: 'Canine',
        weight: weight,
      ),
      owner: const MedicalDocumentOwnerEntity(
        name: 'Tutor extraído',
        identification: 'DOC-99',
        phone: '3000000000',
      ),
      issuer: const {
        'name': 'Veterinaria extraída',
        'clinic': 'Clínica extraída',
      },
    ),
    version: 1,
  );
}

SharedFilePatientAnalysisEntity _appPatient({required String weight}) {
  return SharedFilePatientAnalysisEntity(
    name: 'Eithan',
    recordId: 'AR-C049',
    species: 'Canino',
    breed: 'Criollo',
    sex: 'Macho',
    age: '7-11 meses',
    weight: weight,
  );
}

const _appTutor = SharedFileTutorAnalysisEntity(
  name: 'Barbara James',
  identification: 'C.C. 1152234567',
  phoneNumber: '(+57) 3124567890',
  email: 'barbara@example.com',
);

const _catalog = MedicalFieldCatalog(
  catalogVersion: '1.0.0',
  locale: 'es-CO',
  category: 'PRESCRIPTION',
  categoryLabel: 'Fórmula',
  sections: [],
  fields: [],
  hiddenTechnicalKeys: {},
);
