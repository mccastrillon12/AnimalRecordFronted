import 'dart:convert';

import 'package:animal_record/features/shared_files/data/services/shared_file_pdf_builder.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
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
          details: [
            SharedFileAnalysisDetailEntity(
              label: 'backendKey',
              value: 'backendValue',
            ),
          ],
          originalUrl: 'https://api.example.test/original/document-1',
        ),
      ],
      sections: const [
        SharedFileAnalysisSectionEntity(
          title: 'Remisión',
          details: [
            SharedFileAnalysisDetailEntity(
              label: 'Destino',
              value: 'Clínica Cardiovet',
            ),
          ],
        ),
      ],
      observations: 'Observaciones variables para el PDF.',
      originalUrl: 'https://api.example.test/original/document-1',
    );
    final bytes = await SharedFilePdfBuilder().build(analysis: analysis);

    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(
      latin1.decode(bytes),
      contains('https://api.example.test/original/document-1'),
    );
  });

  test('generates one combined PDF for multiple clinical histories', () async {
    const analysis = SharedFileAnalysisEntity(
      documentType: 'Historia clínica',
      documentNumber: '',
      date: null,
      originalFileName: 'historia.pdf',
      patient: SharedFilePatientAnalysisEntity(
        name: 'Panchita',
        recordId: '',
        species: '',
        breed: '',
        age: '',
        weight: '',
        additionalDetails: [
          SharedFileAnalysisDetailEntity(label: 'Species', value: 'Canine'),
        ],
      ),
      tutor: SharedFileTutorAnalysisEntity(
        name: 'Maria Perez',
        identification: '',
        phoneNumber: '',
        additionalDetails: [
          SharedFileAnalysisDetailEntity(label: 'Phone', value: '3001234567'),
        ],
      ),
    );
    final builder = SharedFilePdfBuilder();

    final single = await builder.build(analysis: analysis);
    final combined = await builder.buildMany(
      analyses: const [analysis, analysis],
    );

    expect(ascii.decode(combined.take(5).toList()), '%PDF-');
    expect(combined.length, greaterThan(single.length));
  });

  test('includes an original link for every vaccination dose', () async {
    const firstUrl = 'https://api.example.test/vaccines/dose-1.pdf';
    const secondUrl = 'https://api.example.test/vaccines/dose-2.pdf';
    const analysis = SharedFileAnalysisEntity(
      documentType: 'Carné de vacunación',
      documentNumber: '',
      date: null,
      originalFileName: '',
      patient: SharedFilePatientAnalysisEntity(
        name: 'Brownie',
        recordId: 'AR-C012',
        species: 'Canino',
        breed: 'Labrador',
        age: '10 años',
        weight: '15 kg',
      ),
      tutor: SharedFileTutorAnalysisEntity(
        name: 'Barbara James',
        identification: 'C.C. 1152234567',
        phoneNumber: '312 456 78 90',
      ),
      itemsTitle: 'Vacuna Rabia',
      sections: [
        SharedFileAnalysisSectionEntity(
          title: 'Próxima dosis',
          body: 'Octubre 27, 2028',
        ),
      ],
      medications: [
        SharedFileMedicationAnalysisEntity(
          name: 'Dosis 1',
          instructions: '',
          details: [
            SharedFileAnalysisDetailEntity(
              label: 'Fecha',
              value: 'Octubre 27, 2025',
            ),
            SharedFileAnalysisDetailEntity(
              label: 'Veterinario',
              value: 'María Ríos',
            ),
          ],
          originalUrl: firstUrl,
        ),
        SharedFileMedicationAnalysisEntity(
          name: 'Dosis 2',
          instructions: '',
          details: [
            SharedFileAnalysisDetailEntity(
              label: 'Fecha',
              value: 'Junio 10, 2024',
            ),
            SharedFileAnalysisDetailEntity(
              label: 'Veterinario',
              value: 'Juanita Doe',
            ),
          ],
          originalUrl: secondUrl,
        ),
      ],
    );

    final bytes = await SharedFilePdfBuilder().build(analysis: analysis);
    final pdfText = latin1.decode(bytes);

    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(pdfText, contains(firstUrl));
    expect(pdfText, contains(secondUrl));
  });

  test('uses the vaccination layout for certificates too', () async {
    const analysis = SharedFileAnalysisEntity(
      documentType: 'Certificado de vacunación',
      documentNumber: '',
      date: null,
      originalFileName: '',
      patient: SharedFilePatientAnalysisEntity(
        name: 'Brownie',
        recordId: 'AR-C012',
        species: 'Canino',
        breed: 'Labrador',
        age: '10 años',
        weight: '15 kg',
      ),
      tutor: SharedFileTutorAnalysisEntity(
        name: 'Barbara James',
        identification: 'C.C. 1152234567',
        phoneNumber: '312 456 78 90',
      ),
      medications: [
        SharedFileMedicationAnalysisEntity(
          name: 'Dosis 1',
          groupTitle: 'Vacuna Rabia',
          instructions: '',
          details: [
            SharedFileAnalysisDetailEntity(
              label: 'Próxima dosis',
              value: 'Octubre 27, 2028',
            ),
            SharedFileAnalysisDetailEntity(
              label: 'Fecha',
              value: 'Octubre 27, 2025',
            ),
            SharedFileAnalysisDetailEntity(
              label: 'Etiqueta',
              value: 'https://example.test/label.png',
            ),
            SharedFileAnalysisDetailEntity(
              label: 'Firma Veterinario',
              value: 'https://example.test/signature.png',
            ),
            SharedFileAnalysisDetailEntity(
              label: 'Veterinario',
              value: 'María Ríos',
            ),
          ],
          originalUrl: 'https://example.test/rabies.pdf',
        ),
      ],
    );

    final bytes = await SharedFilePdfBuilder().build(analysis: analysis);
    final pdfText = latin1.decode(bytes);

    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(pdfText, contains('https://example.test/rabies.pdf'));
    expect(pdfText, isNot(contains('https://example.test/label.png')));
    expect(pdfText, isNot(contains('https://example.test/signature.png')));
  });
}
