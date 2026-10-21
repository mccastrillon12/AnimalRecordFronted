import 'dart:io';

import 'package:animal_record/features/shared_files/data/services/shared_file_pdf_builder.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';

Future<void> main() async {
  final analysis = SharedFileAnalysisEntity(
    documentType: 'Fórmula médica',
    documentNumber: 'N° F-57-11230',
    date: DateTime(2026, 1, 25),
    originalFileName: 'formula_original.pdf',
    originalMimeType: 'application/pdf',
    patient: const SharedFilePatientAnalysisEntity(
      name: 'Paciente extraído del archivo',
      recordId: 'DOC-101077',
      species: 'Canine',
      breed: 'Labrador',
      sex: 'Male',
      age: '10 years',
      weight: '15 kg',
    ),
    tutor: const SharedFileTutorAnalysisEntity(
      name: 'Tutor extraído del archivo',
      identification: '101077',
      phoneNumber: '3000000000',
    ),
    pdfPatient: const SharedFilePatientAnalysisEntity(
      name: 'Eithan',
      recordId: 'AR-C049',
      species: 'Canino',
      breed: 'Criollo',
      sex: 'Macho',
      age: '7-11 meses',
      weight: '15 kg',
    ),
    pdfTutor: const SharedFileTutorAnalysisEntity(
      name: 'Barbara James',
      identification: 'C.C. 1152234567',
      phoneNumber: '(+57) 312 456 78 90',
      email: 'barbara@example.com',
    ),
    veterinarian: const SharedFileVeterinarianAnalysisEntity(
      name: 'Natalia López',
      clinic: 'CISVET Clínica Veterinaria',
      professionalId: '41611',
    ),
    itemsTitle: 'Medicamentos',
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
  final logoBytes = await File('assets/Logo/Logotipo_azul.png').readAsBytes();
  final bytes = await SharedFilePdfBuilder().build(
    analysis: analysis,
    logoBytes: logoBytes,
  );
  final outputDirectory = Directory('output/pdf');
  await outputDirectory.create(recursive: true);
  await File(
    '${outputDirectory.path}/formula_medica_ejemplo.pdf',
  ).writeAsBytes(bytes);
}
