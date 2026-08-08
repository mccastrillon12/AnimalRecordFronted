import 'dart:io';

import 'package:animal_record/features/shared_files/data/services/shared_file_pdf_builder.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';

Future<void> main() async {
  final analysis = SharedFileAnalysisEntity(
    documentType: 'Fórmula médica',
    documentNumber: 'N° 11230',
    date: DateTime(2026, 1, 25),
    originalFileName: 'CertificadoPos_1037238472.pdf',
    patient: const SharedFilePatientAnalysisEntity(
      name: 'Brownie',
      recordId: 'AR-C012',
      species: 'Canino',
      breed: 'Labrador',
      age: '10 años',
      weight: '15 kg',
    ),
    tutor: const SharedFileTutorAnalysisEntity(
      name: 'Barbara James',
      identification: 'C.C. 1152234567',
      phoneNumber: '(+57) 312 456 78 90',
    ),
    medications: const [
      SharedFileMedicationAnalysisEntity(
        name: 'ProtectionPets suspensión oral',
        quantity: 1,
        instructions:
            'Administrar 2gr vía oral cada 24 horas durante 7 días, siempre '
            'con el estómago lleno.',
      ),
      SharedFileMedicationAnalysisEntity(
        name: 'CBD gotas (verde)',
        quantity: 1,
        instructions:
            'Administrar vía oral de 3 a 5 gotas cada 24 horas durante 30 '
            'días. Suspender 15 días y reiniciar 30 días.',
      ),
    ],
    observations:
        r'Realizar coprológico seriado, traer 3 muestras de materia fecal de '
        r'diferentes días, una cada día, valor $40.000',
  );
  final clipboardSvg = await File(
    'assets/icons/clipboard-import.svg',
  ).readAsString();
  final bytes = await SharedFilePdfBuilder().build(
    analysis: analysis,
    clipboardSvg: clipboardSvg,
  );
  final outputDirectory = Directory('output/pdf');
  await outputDirectory.create(recursive: true);
  await File(
    '${outputDirectory.path}/formula_medica_ejemplo.pdf',
  ).writeAsBytes(bytes);
}
