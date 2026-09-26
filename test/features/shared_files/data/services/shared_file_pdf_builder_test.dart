import 'dart:convert';

import 'package:animal_record/features/shared_files/data/services/shared_file_pdf_builder.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'starts a new PDF line after each sentence without changing decimals or links',
    () {
      expect(
        pdfSentenceLineBreaks(
          'Medida 3.58 x 2.00 cm. Normal.\tVer https://example.com/informe.pdf. Control.',
        ),
        'Medida 3.58 x 2.00 cm.\nNormal.\nVer https://example.com/informe.pdf.\nControl.',
      );
      expect(
        pdfSentenceLineBreaks('Normal.\nControl.\n'),
        'Normal.\nControl.\n',
      );
    },
  );

  for (final documentType in [
    'Fórmula',
    'Orden médica',
    'Remisión',
    'Historia clínica',
    'Resultados de laboratorio',
    'Archivo no identificado',
    'Carnet de vacunación',
    'Certificado de vacunación',
  ]) {
    test('flows long content across pages for $documentType', () async {
      final narrative = List.generate(
        100,
        (index) => 'Línea ${index + 1}: texto completo del documento.',
      ).join('\n');
      final analysis = SharedFileAnalysisEntity(
        documentType: documentType,
        documentNumber: '',
        date: null,
        originalFileName: '',
        patient: SharedFilePatientAnalysisEntity(
          name: 'Paciente',
          recordId: '',
          species: '',
          breed: '',
          age: '',
          weight: '',
          additionalDetails: [
            SharedFileAnalysisDetailEntity(label: 'Notas', value: narrative),
          ],
        ),
        tutor: const SharedFileTutorAnalysisEntity(
          name: '',
          identification: '',
          phoneNumber: '',
        ),
        medications: [
          SharedFileMedicationAnalysisEntity(
            name: 'Registro médico',
            groupTitle: 'Vacuna Rabia',
            instructions: narrative,
            details: [
              SharedFileAnalysisDetailEntity(
                label: 'Observaciones',
                value: narrative,
              ),
            ],
          ),
        ],
        sections: [
          SharedFileAnalysisSectionEntity(title: 'Informe', body: narrative),
        ],
        observations: narrative,
      );
      final bytes = await SharedFilePdfBuilder().build(analysis: analysis);
      expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
      expect(
        RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(bytes)).length,
        greaterThan(1),
      );
    });
  }

  test('paginates diagnostic findings longer than a whole page', () async {
    final analysis = SharedFileAnalysisEntity(
      documentType: 'Imagen diagnóstica',
      documentNumber: '',
      date: null,
      originalFileName: 'ecografia.pdf',
      patient: const SharedFilePatientAnalysisEntity(
        name: '',
        recordId: '',
        species: '',
        breed: '',
        age: '',
        weight: '',
      ),
      tutor: const SharedFileTutorAnalysisEntity(
        name: '',
        identification: '',
        phoneNumber: '',
      ),
      sections: [
        SharedFileAnalysisSectionEntity(
          title: 'Información general',
          details: const [
            SharedFileAnalysisDetailEntity(
              label: 'Observaciones reportadas',
              value: 'Estudio ecográfico con hallazgos narrativos completos.',
            ),
          ],
        ),
        SharedFileAnalysisSectionEntity(
          title: 'Imágenes diagnósticas',
          details: [
            SharedFileAnalysisDetailEntity(
              label: 'Hallazgos reportados',
              value: List.generate(
                120,
                (index) =>
                    'Órgano ${index + 1}: hallazgo completo del informe.',
              ).join('\n'),
            ),
            const SharedFileAnalysisDetailEntity(
              label: 'Conclusión reportada',
              value: 'Correlacionar con los signos clínicos.',
            ),
          ],
        ),
      ],
    );
    final bytes = await SharedFilePdfBuilder().build(analysis: analysis);
    final pageCount = RegExp(
      r'/Type\s*/Page\b',
    ).allMatches(latin1.decode(bytes)).length;
    expect(pageCount, inInclusiveRange(2, 4));
  });

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
      isNot(contains('https://api.example.test/original/document-1')),
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

  test('does not include original links for vaccination doses', () async {
    const firstUrl = 'https://api.example.test/vaccines/dose-1.pdf';
    const secondUrl = 'https://api.example.test/vaccines/dose-2.pdf';
    const analysis = SharedFileAnalysisEntity(
      documentType: 'Carnet de vacunación',
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
    expect(pdfText, isNot(contains(firstUrl)));
    expect(pdfText, isNot(contains(secondUrl)));
  });

  test('recognizes card and certificate vaccination PDF titles', () {
    expect(isVaccinationPdfDocumentType('Carnet de vacunación'), isTrue);
    expect(isVaccinationPdfDocumentType('Carné de vacunación'), isTrue);
    expect(isVaccinationPdfDocumentType('Certificado de vacunación'), isTrue);
    expect(isVaccinationPdfDocumentType('Historia clínica'), isFalse);
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
    expect(pdfText, isNot(contains('https://example.test/rabies.pdf')));
    expect(pdfText, isNot(contains('https://example.test/label.png')));
    expect(pdfText, isNot(contains('https://example.test/signature.png')));
  });
}
