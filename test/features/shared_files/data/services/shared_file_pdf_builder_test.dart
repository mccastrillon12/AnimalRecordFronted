import 'dart:convert';

import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/features/shared_files/data/services/shared_file_pdf_builder.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates a valid PDF from variable analysis data', () async {
    final analysis = SharedFileAnalysisEntity(
      documentType: 'Fórmula médica',
      documentNumber: 'N° PDF-42',
      date: DateTime(2026, 1, 25),
      originalFileName: 'variable.pdf',
      patient: const SharedFilePatientAnalysisEntity(
        name: 'Paciente PDF',
        recordId: 'AR-PDF',
        species: 'Canino',
        breed: 'Labrador',
        age: '10 años',
        weight: '15 kg',
      ),
      tutor: const SharedFileTutorAnalysisEntity(
        name: 'Tutor PDF',
        identification: 'C.C. PDF',
        phoneNumber: '300 000 0000',
      ),
      medications: const [
        SharedFileMedicationAnalysisEntity(
          name: 'Medicamento PDF',
          quantity: 2,
          instructions: 'Indicaciones variables para el PDF.',
        ),
      ],
      observations: 'Observaciones variables para el PDF.',
    );
    final clipboardSvg = await rootBundle.loadString(AppIcons.clipboardImport);

    final bytes = await SharedFilePdfBuilder().build(
      analysis: analysis,
      clipboardSvg: clipboardSvg,
    );

    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
  });
}
