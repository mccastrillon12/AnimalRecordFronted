import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_field_catalog.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/vaccination_group_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groups vaccines while labels come from the backend catalog', () {
    final groups = groupVaccinations([
      _document(
        'old',
        const MedicalDocumentItemEntity(
          id: 'one',
          fields: {
            'name': 'Rabies',
            'applicationDate': '7/01/24',
            'nextDoseDate': '7/01/25',
          },
        ),
      ),
      _document(
        'new',
        const MedicalDocumentItemEntity(
          id: 'two',
          fields: {
            'name': 'Rabia',
            'applicationDate': '7/01/25',
            'nextDoseDate': '7/01/26',
          },
        ),
      ),
    ], _catalog);

    expect(groups, hasLength(1));
    expect(groups.single.key, 'rabies');
    expect(groups.single.latest.document.id, 'new');
    expect(groups.single.latest.applicationDateLabel, 'Fecha de aplicación');
    expect(groups.single.latest.nextDoseDateLabel, 'Próxima dosis');
  });

  test('shows only catalog columns and never humanizes unknown keys', () {
    final group = groupVaccinations([
      _document(
        'document-1',
        const MedicalDocumentItemEntity(
          id: 'one',
          fields: {
            'name': 'Rabia',
            'applicationDate': '7/01/25',
            'brand': 'Virbac',
            'classificationConfidence': .88,
            'futureInternalKey': 'No mostrar',
          },
        ),
      ),
    ], _catalog).single;

    final detail = vaccinationDetailViewData(group, _catalog);

    expect(detail.doses.single.details.map((item) => item.label), [
      'Fecha de aplicación',
      'Marca',
    ]);
    expect(
      detail.doses.single.details.map((item) => item.value),
      isNot(contains('No mostrar')),
    );
  });
}

MedicalDocumentEntity _document(
  String id,
  MedicalDocumentItemEntity vaccination,
) {
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
      vaccinations: [vaccination],
    ),
    version: 1,
  );
}

const _catalog = MedicalFieldCatalog(
  catalogVersion: '1.0.0',
  locale: 'es-CO',
  category: 'VACCINATION_CARD',
  categoryLabel: 'Carné de vacunación',
  sections: [
    MedicalFieldSection(key: 'vaccinations', label: 'Vacunas', order: 10),
  ],
  fields: [
    MedicalFieldDefinition(
      path: 'vaccinations',
      label: 'Vacunas',
      sectionKey: 'vaccinations',
      order: 10,
      kind: MedicalFieldKind.table,
      editable: true,
      hideWhenEmpty: true,
      columns: [
        MedicalTableColumn(
          key: 'name',
          label: 'Vacuna',
          order: 10,
          kind: MedicalFieldKind.text,
          editable: true,
          hideWhenEmpty: true,
        ),
        MedicalTableColumn(
          key: 'applicationDate',
          label: 'Fecha de aplicación',
          order: 20,
          kind: MedicalFieldKind.date,
          editable: true,
          hideWhenEmpty: true,
        ),
        MedicalTableColumn(
          key: 'nextDoseDate',
          label: 'Próxima dosis',
          order: 30,
          kind: MedicalFieldKind.date,
          editable: true,
          hideWhenEmpty: true,
        ),
        MedicalTableColumn(
          key: 'brand',
          label: 'Marca',
          order: 40,
          kind: MedicalFieldKind.text,
          editable: true,
          hideWhenEmpty: true,
        ),
        MedicalTableColumn(
          key: 'classificationConfidence',
          label: 'Confianza de clasificación',
          order: 50,
          kind: MedicalFieldKind.text,
          editable: false,
          hideWhenEmpty: true,
        ),
      ],
    ),
  ],
  hiddenTechnicalKeys: {'id', 'confidence', 'source'},
);
