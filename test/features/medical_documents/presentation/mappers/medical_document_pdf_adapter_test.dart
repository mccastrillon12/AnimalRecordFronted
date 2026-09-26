import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_field_catalog.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_display_formatter.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_pdf_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defines every document type label in the category enum', () {
    expect(
      {
        for (final category in MedicalDocumentCategory.values)
          category.wireValue: category.label,
      },
      {
        'PRESCRIPTION': 'Fórmula',
        'MEDICAL_ORDER': 'Orden médica',
        'REFERRAL': 'Remisión',
        'VACCINATION_CARD': 'Carnet de vacunación',
        'CLINICAL_HISTORY': 'Historia clínica',
        'DIAGNOSTIC_IMAGE': 'Imagen diagnóstica',
        'LABORATORY_RESULT': 'Resultados de laboratorio',
        'OTHER': 'Archivo no identificado',
      },
    );
  });

  test('does not remove underscores from ordinary extracted values', () {
    expect(medicalDocumentDisplayValue('NEEDS_REVIEW'), 'NEEDS_REVIEW');
  });

  test('breaks narrative lines after periods without splitting decimals', () {
    expect(
      medicalDocumentNarrativeDisplayValue(
        'Hallazgo uno. Hallazgo dos (3.58 X 2.00 cm). Conclusión.\nNota final.',
      ),
      'Hallazgo uno.\nHallazgo dos (3.58 X 2.00 cm).\nConclusión.\nNota final.',
    );
  });

  test('always hides warnings as technical metadata', () {
    for (final key in ['warning', 'warnings', 'advertencia', 'advertencias']) {
      expect(isMedicalDocumentTechnicalKey(key, const {}), isTrue);
    }
  });

  test('always hides summaries and identifier fragments', () {
    for (final key in [
      'summary',
      'Resumen',
      'patientHints',
      'identifierFragments',
      'Fragmentos identificadores',
    ]) {
      expect(isMedicalDocumentTechnicalKey(key, const {}), isTrue);
    }

    const extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.clinicalHistory,
      summary: 'Resumen que no debe mostrarse',
      patientHints: ['Fragmento que no debe mostrarse'],
      rawExtraction: {
        'summary': 'Resumen crudo que no debe mostrarse',
        'patientHints': ['Fragmento crudo que no debe mostrarse'],
      },
    );
    const catalog = MedicalFieldCatalog(
      catalogVersion: '1.0.0',
      locale: 'es-CO',
      category: 'CLINICAL_HISTORY',
      categoryLabel: 'Historia clínica',
      sections: [
        MedicalFieldSection(
          key: 'general',
          label: 'Información general',
          order: 10,
        ),
      ],
      fields: [
        MedicalFieldDefinition(
          path: 'summary',
          label: 'Resumen',
          sectionKey: 'general',
          order: 10,
          kind: MedicalFieldKind.longText,
          editable: false,
          hideWhenEmpty: true,
        ),
        MedicalFieldDefinition(
          path: 'patientHints',
          label: 'Fragmentos identificadores',
          sectionKey: 'general',
          order: 20,
          kind: MedicalFieldKind.list,
          editable: false,
          hideWhenEmpty: true,
        ),
      ],
      hiddenTechnicalKeys: {},
    );

    final analysis = medicalDocumentToAnalysis(
      document: _document,
      extraction: extraction,
      catalog: catalog,
      displayCategory: MedicalDocumentCategory.prescription,
      includeUncataloguedFields: true,
    );
    final details = analysis.sections.expand((section) => section.details);

    expect(details.map((detail) => detail.label), isNot(contains('Resumen')));
    expect(
      details.map((detail) => detail.label),
      isNot(contains('Fragmentos identificadores')),
    );
    expect(
      details.map((detail) => detail.value).join(' '),
      isNot(contains('no debe mostrarse')),
    );
  });

  test('uses catalog labels for every canonical path and table column', () {
    const extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.clinicalHistory,
      documentTypeConfidence: .7828133,
      documentDate: '07-01-26',
      patient: MedicalDocumentPatientEntity(
        name: 'Chuleta',
        identifier: '16521',
        species: 'Canine',
      ),
      clinicalHistory: {'reasonForConsultation': 'Control general'},
      diagnosticResults: [
        MedicalDocumentItemEntity(
          id: 'result-1',
          confidence: .91,
          fields: {'name': 'Hemograma', 'result': 'Sin observaciones'},
        ),
      ],
    );
    const document = MedicalDocumentEntity(
      id: 'document-1',
      documentCode: 'H-57-16',
      animalIds: ['animal-1'],
      originalFileName: 'Records-2026.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.reviewPending,
      version: 1,
    );

    final analysis = medicalDocumentToAnalysis(
      document: document,
      extraction: extraction,
      catalog: _catalog,
    );

    expect(analysis.documentType, 'Historia clínica');
    expect(analysis.sourceDateLabel, 'Fecha del documento');
    expect(analysis.originalFileNameLabel, 'Archivo original');
    expect(analysis.patient.name, 'Chuleta');
    expect(analysis.patient.additionalDetails.map((detail) => detail.label), [
      'Identificador',
      'Especie',
    ]);
    final details = [
      ...analysis.patient.additionalDetails,
      ...analysis.sections.expand((section) => section.details),
    ];
    expect(
      details.map((e) => e.label),
      containsAll([
        'Identificador',
        'Especie',
        'Tipo de documento',
        'Motivo de consulta',
        'Prueba',
        'Resultado reportado',
      ]),
    );
    expect(details.map((detail) => detail.value), contains('Historia clínica'));
    expect(
      details.map((detail) => detail.label.toLowerCase()),
      isNot(contains(contains('confianza'))),
    );
    expect(details.map((detail) => detail.value), isNot(contains('0.7828133')));
  });

  test('renders additional fields generically without exposing their keys', () {
    const extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.clinicalHistory,
      additionalFields: {
        'unknownEnglishKey': 'Valor uno',
        'anotherInternalName': 'Valor dos',
        'classificationConfidence': .55,
      },
      preservedUnknownFields: {'futureInternalMetadata': 'no mostrar'},
    );

    final analysis = medicalDocumentToAnalysis(
      document: _document,
      extraction: extraction,
      catalog: _catalog,
    );
    final details = analysis.sections
        .where((section) => section.title == 'Información adicional')
        .expand((section) => section.details)
        .toList(growable: false);

    expect(details.map((detail) => detail.label), [
      'Campo adicional 1',
      'Campo adicional 2',
    ]);
    expect(details.map((detail) => detail.value), ['Valor uno', 'Valor dos']);
    expect(
      details.map((detail) => detail.label),
      isNot(contains('futureInternalMetadata')),
    );
  });

  test('renders unknown non-technical values only for category overrides', () {
    const extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.clinicalHistory,
      rawExtraction: {
        'documentType': 'CLINICAL_HISTORY',
        'documentTypeConfidence': 0.93,
        'warnings': [
          'the document did not match a configured extraction blueprint',
        ],
        'futureSection': {
          'medicalValue': 'Valor clínico futuro',
          'classificationConfidence': 0.71,
          'warning': 'internal warning',
          'verified': true,
        },
      },
    );

    final matching = medicalDocumentToAnalysis(
      document: _document,
      extraction: extraction,
      catalog: _catalog,
    );
    final overridden = medicalDocumentToAnalysis(
      document: _document,
      extraction: extraction,
      catalog: _catalog,
      displayCategory: MedicalDocumentCategory.prescription,
      includeUncataloguedFields: true,
    );

    expect(
      matching.sections.where(
        (section) => section.title == 'Información adicional extraída',
      ),
      isEmpty,
    );
    final additional = overridden.sections.singleWhere(
      (section) => section.title == 'Información adicional extraída',
    );
    expect(
      additional.details.map((detail) => detail.value),
      containsAll(['Valor clínico futuro', 'true']),
    );
    expect(
      additional.details.map((detail) => detail.value),
      isNot(contains('0.93')),
    );
    expect(
      additional.details.map((detail) => detail.value),
      isNot(contains('0.71')),
    );
    expect(
      additional.details.map((detail) => detail.value),
      isNot(
        contains(
          'the document did not match a configured extraction blueprint',
        ),
      ),
    );
    expect(
      additional.details.map((detail) => detail.value),
      isNot(contains('internal warning')),
    );
    expect(overridden.documentType, MedicalDocumentCategory.prescription.label);
  });

  test('uses the saved category when the document type is unidentified', () {
    const extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.other,
      rawExtraction: {'documentType': 'OTHER'},
    );

    final analysis = medicalDocumentToAnalysis(
      document: _document,
      extraction: extraction,
      catalog: _catalog,
      displayCategory: MedicalDocumentCategory.diagnosticImage,
      includeUncataloguedFields: true,
    );
    final documentType = analysis.sections
        .expand((section) => section.details)
        .singleWhere((detail) => detail.label == 'Tipo de documento');

    expect(
      analysis.documentType,
      MedicalDocumentCategory.diagnosticImage.label,
    );
    expect(documentType.value, MedicalDocumentCategory.other.label);
  });

  test('keeps extracted values unchanged', () {
    const extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.clinicalHistory,
      patient: MedicalDocumentPatientEntity(
        species: 'Canine',
        reproductiveStatus: 'Neutered',
      ),
    );

    final analysis = medicalDocumentToAnalysis(
      document: _document,
      extraction: extraction,
      catalog: _catalog,
    );
    final values = analysis.patient.additionalDetails.map(
      (detail) => detail.value,
    );

    expect(values, containsAll(['Canine', 'Neutered']));
  });

  test('shows reported narrative in full and hides legacy summary', () {
    const narrative = 'Hallazgo del hígado. Hallazgo del bazo';
    const extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.diagnosticImage,
      summary: 'Resumen generado',
      reportedSummary: 'Resumen escrito',
      reportedRecommendations: 'Control en siete días',
      reportedObservations: '',
      diagnosticImages: [
        MedicalDocumentItemEntity(
          id: 'image-1',
          fields: {
            'name': 'Ecografía',
            'reportedTechnique': 'Sonda 9 MHz',
            'reportedFindings': narrative,
            'reportedConclusion': 'Conclusión escrita',
            'reportedDiagnosis': 'Diagnóstico escrito',
          },
        ),
      ],
    );
    const catalog = MedicalFieldCatalog(
      catalogVersion: '1.1.0',
      locale: 'es-CO',
      category: 'DIAGNOSTIC_IMAGE',
      categoryLabel: 'Imagen diagnóstica',
      sections: [
        MedicalFieldSection(key: 'report', label: 'Informe', order: 1),
      ],
      fields: [
        MedicalFieldDefinition(
          path: 'summary',
          label: 'Resumen anterior',
          sectionKey: 'report',
          order: 0,
          kind: MedicalFieldKind.longText,
          editable: false,
          hideWhenEmpty: true,
        ),
        MedicalFieldDefinition(
          path: 'reportedSummary',
          label: 'Resumen',
          sectionKey: 'report',
          order: 1,
          kind: MedicalFieldKind.longText,
          editable: true,
          hideWhenEmpty: true,
        ),
        MedicalFieldDefinition(
          path: 'reportedRecommendations',
          label: 'Recomendaciones',
          sectionKey: 'report',
          order: 2,
          kind: MedicalFieldKind.longText,
          editable: true,
          hideWhenEmpty: true,
        ),
        MedicalFieldDefinition(
          path: 'reportedObservations',
          label: 'Observaciones',
          sectionKey: 'report',
          order: 3,
          kind: MedicalFieldKind.longText,
          editable: true,
          hideWhenEmpty: false,
        ),
        MedicalFieldDefinition(
          path: 'diagnosticImages',
          label: 'Imágenes diagnósticas',
          sectionKey: 'report',
          order: 4,
          kind: MedicalFieldKind.table,
          editable: true,
          hideWhenEmpty: true,
          columns: [
            MedicalTableColumn(
              key: 'reportedTechnique',
              label: 'Técnica',
              order: 1,
              kind: MedicalFieldKind.longText,
              editable: true,
              hideWhenEmpty: true,
            ),
            MedicalTableColumn(
              key: 'reportedFindings',
              label: 'Hallazgos',
              order: 2,
              kind: MedicalFieldKind.longText,
              editable: true,
              hideWhenEmpty: true,
            ),
            MedicalTableColumn(
              key: 'reportedConclusion',
              label: 'Conclusión',
              order: 3,
              kind: MedicalFieldKind.longText,
              editable: true,
              hideWhenEmpty: true,
            ),
            MedicalTableColumn(
              key: 'reportedDiagnosis',
              label: 'Diagnóstico',
              order: 4,
              kind: MedicalFieldKind.longText,
              editable: true,
              hideWhenEmpty: true,
            ),
          ],
        ),
      ],
      hiddenTechnicalKeys: {},
    );
    final analysis = medicalDocumentToAnalysis(
      document: _document,
      extraction: extraction,
      catalog: catalog,
      displayCategory: MedicalDocumentCategory.laboratoryResult,
    );
    final details = analysis.sections
        .expand((section) => section.details)
        .toList();
    expect(
      details.map((detail) => detail.value),
      contains('Hallazgo del hígado.\nHallazgo del bazo'),
    );
    expect(extraction.diagnosticImages.single.reportedFindings, narrative);
    expect(details.map((detail) => detail.value), contains('Resumen escrito'));
    expect(
      details.map((detail) => detail.value),
      contains('Control en siete días'),
    );
    expect(
      details.map((detail) => detail.label),
      isNot(contains('Resumen anterior')),
    );
    expect(
      details.map((detail) => detail.label),
      isNot(contains('Observaciones')),
    );
  });
}

const _document = MedicalDocumentEntity(
  id: 'document-1',
  animalIds: ['animal-1'],
  originalFileName: 'historia.pdf',
  mimeType: 'application/pdf',
  fileSize: 100,
  status: MedicalDocumentStatus.accepted,
  version: 1,
);

const _catalog = MedicalFieldCatalog(
  catalogVersion: '1.0.0',
  locale: 'es-CO',
  category: 'CLINICAL_HISTORY',
  categoryLabel: 'Historia clínica',
  sections: [
    MedicalFieldSection(
      key: 'general',
      label: 'Información general',
      order: 10,
    ),
    MedicalFieldSection(key: 'patient', label: 'Paciente', order: 20),
    MedicalFieldSection(
      key: 'clinicalHistory',
      label: 'Historia clínica',
      order: 30,
    ),
    MedicalFieldSection(
      key: 'diagnosticResults',
      label: 'Resultados diagnósticos',
      order: 40,
    ),
    MedicalFieldSection(
      key: 'additional',
      label: 'Información adicional',
      order: 90,
    ),
  ],
  fields: [
    MedicalFieldDefinition(
      path: 'documentType',
      label: 'Tipo de documento',
      sectionKey: 'general',
      order: 5,
      kind: MedicalFieldKind.text,
      editable: false,
      hideWhenEmpty: true,
    ),
    MedicalFieldDefinition(
      path: 'documentTypeConfidence',
      label: 'Confianza de clasificación',
      sectionKey: 'general',
      order: 7,
      kind: MedicalFieldKind.text,
      editable: false,
      hideWhenEmpty: true,
    ),
    MedicalFieldDefinition(
      path: 'documentDate',
      label: 'Fecha del documento',
      sectionKey: 'general',
      order: 10,
      kind: MedicalFieldKind.date,
      editable: true,
      hideWhenEmpty: true,
    ),
    MedicalFieldDefinition(
      path: 'patient.name',
      label: 'Nombre del paciente',
      sectionKey: 'patient',
      order: 10,
      kind: MedicalFieldKind.text,
      editable: true,
      hideWhenEmpty: true,
    ),
    MedicalFieldDefinition(
      path: 'patient.identifier',
      label: 'Identificador',
      sectionKey: 'patient',
      order: 20,
      kind: MedicalFieldKind.text,
      editable: true,
      hideWhenEmpty: true,
    ),
    MedicalFieldDefinition(
      path: 'patient.species',
      label: 'Especie',
      sectionKey: 'patient',
      order: 30,
      kind: MedicalFieldKind.text,
      editable: true,
      hideWhenEmpty: true,
    ),
    MedicalFieldDefinition(
      path: 'patient.reproductiveStatus',
      label: 'Estado reproductivo',
      sectionKey: 'patient',
      order: 40,
      kind: MedicalFieldKind.text,
      editable: true,
      hideWhenEmpty: true,
    ),
    MedicalFieldDefinition(
      path: 'clinicalHistory.reasonForConsultation',
      label: 'Motivo de consulta',
      sectionKey: 'clinicalHistory',
      order: 10,
      kind: MedicalFieldKind.longText,
      editable: true,
      hideWhenEmpty: true,
    ),
    MedicalFieldDefinition(
      path: 'diagnosticResults',
      label: 'Resultado diagnóstico',
      sectionKey: 'diagnosticResults',
      order: 10,
      kind: MedicalFieldKind.table,
      editable: true,
      hideWhenEmpty: true,
      columns: [
        MedicalTableColumn(
          key: 'name',
          label: 'Prueba',
          order: 10,
          kind: MedicalFieldKind.text,
          editable: true,
          hideWhenEmpty: true,
        ),
        MedicalTableColumn(
          key: 'result',
          label: 'Resultado reportado',
          order: 20,
          kind: MedicalFieldKind.text,
          editable: true,
          hideWhenEmpty: true,
        ),
      ],
    ),
    MedicalFieldDefinition(
      path: 'additionalFields',
      label: 'Información adicional',
      sectionKey: 'additional',
      order: 10,
      kind: MedicalFieldKind.dynamicObject,
      editable: true,
      hideWhenEmpty: true,
      fallbackLabel: 'Campo adicional',
    ),
  ],
  hiddenTechnicalKeys: {'id', 'confidence', 'source'},
);
