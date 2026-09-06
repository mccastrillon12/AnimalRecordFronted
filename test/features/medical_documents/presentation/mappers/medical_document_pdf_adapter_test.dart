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
        'PRESCRIPTION': 'Formula',
        'MEDICAL_ORDER': 'Orden medica',
        'REFERRAL': 'Remisión',
        'VACCINATION_CARD': 'Carnet de vacunación',
        'CLINICAL_HISTORY': 'Historia clinica',
        'DIAGNOSTIC_IMAGE': 'Imagen Diagnostica',
        'LABORATORY_RESULT': 'Resultados de laboratorio',
        'OTHER': 'Archivo no identificado',
      },
    );
  });

  test('does not remove underscores from ordinary extracted values', () {
    expect(medicalDocumentDisplayValue('NEEDS_REVIEW'), 'NEEDS_REVIEW');
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

    expect(analysis.documentType, 'Historia clinica');
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
    expect(details.map((detail) => detail.value), contains('Historia clinica'));
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
        'futureSection': {
          'medicalValue': 'Valor clínico futuro',
          'classificationConfidence': 0.71,
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
    expect(overridden.documentType, MedicalDocumentCategory.prescription.label);
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
