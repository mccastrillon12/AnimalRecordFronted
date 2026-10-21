import 'dart:convert';

import 'package:animal_record/features/shared_files/data/services/shared_file_pdf_builder.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates only the compact Animal Record page', () async {
    final analysis = _analysis(
      sections: [
        SharedFileAnalysisSectionEntity(
          title: 'Contenido médico que no pertenece al resumen',
          body: List.filled(200, 'Texto del documento original.').join(' '),
        ),
      ],
      medications: const [
        SharedFileMedicationAnalysisEntity(
          name: 'Medicamento que no pertenece al resumen',
          instructions: 'Indicaciones',
        ),
      ],
    );

    final bytes = await SharedFilePdfBuilder().build(analysis: analysis);

    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(_pageCount(bytes), 1);
  });

  test('creates one Animal Record page for every analysis', () async {
    final bytes = await SharedFilePdfBuilder().buildMany(
      analyses: [_analysis(), _analysis()],
    );

    expect(_pageCount(bytes), 2);
  });

  test('supports omitted optional tutor and patient fields', () async {
    final bytes = await SharedFilePdfBuilder().build(
      analysis: _analysis(
        patient: const SharedFilePatientAnalysisEntity(
          name: 'Eithan',
          recordId: 'AR-C049',
          species: 'Canino',
          breed: '',
          age: '',
          weight: '',
        ),
        tutor: const SharedFileTutorAnalysisEntity(
          name: 'Barbara James',
          identification: '',
          phoneNumber: '',
        ),
      ),
    );

    expect(_pageCount(bytes), 1);
  });
}

SharedFileAnalysisEntity _analysis({
  SharedFilePatientAnalysisEntity patient =
      const SharedFilePatientAnalysisEntity(
        name: 'Eithan',
        recordId: 'AR-C049',
        species: 'Canino',
        breed: 'Criollo',
        sex: 'Macho',
        age: '7-11 meses',
        weight: '15 kg',
      ),
  SharedFileTutorAnalysisEntity tutor = const SharedFileTutorAnalysisEntity(
    name: 'Barbara James',
    identification: 'C.C. 1152234567',
    phoneNumber: '(+57) 3124567890',
    email: 'barbara@example.com',
  ),
  List<SharedFileAnalysisSectionEntity> sections = const [],
  List<SharedFileMedicationAnalysisEntity> medications = const [],
}) {
  return SharedFileAnalysisEntity(
    documentType: 'Fórmula médica',
    documentNumber: 'N° F-57-11230',
    date: null,
    originalFileName: 'formula.pdf',
    originalMimeType: 'application/pdf',
    patient: patient,
    tutor: tutor,
    sections: sections,
    medications: medications,
  );
}

int _pageCount(List<int> bytes) =>
    RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(bytes)).length;
