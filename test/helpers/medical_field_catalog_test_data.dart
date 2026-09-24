import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_field_catalog.dart';
import 'package:animal_record/features/medical_documents/domain/repositories/medical_documents_repository.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/services/medical_document_analysis_presenter.dart';

void registerMedicalFieldCatalogTestDependencies() {
  final useCase = _TestMedicalFieldCatalogUseCase();
  if (di.sl.isRegistered<GetMedicalFieldCatalogUseCase>()) {
    di.sl.unregister<GetMedicalFieldCatalogUseCase>();
  }
  if (di.sl.isRegistered<MedicalDocumentAnalysisPresenter>()) {
    di.sl.unregister<MedicalDocumentAnalysisPresenter>();
  }
  di.sl.registerSingleton<GetMedicalFieldCatalogUseCase>(useCase);
  di.sl.registerSingleton<MedicalDocumentAnalysisPresenter>(
    MedicalDocumentAnalysisPresenter(getFieldCatalog: useCase),
  );
}

void unregisterMedicalFieldCatalogTestDependencies() {
  if (di.sl.isRegistered<MedicalDocumentAnalysisPresenter>()) {
    di.sl.unregister<MedicalDocumentAnalysisPresenter>();
  }
  if (di.sl.isRegistered<GetMedicalFieldCatalogUseCase>()) {
    di.sl.unregister<GetMedicalFieldCatalogUseCase>();
  }
}

class _TestMedicalFieldCatalogUseCase implements GetMedicalFieldCatalogUseCase {
  @override
  MedicalDocumentsRepository get repository => throw UnimplementedError();

  @override
  Future<MedicalFieldCatalog> call({
    required MedicalDocumentCategory category,
    String locale = 'es-CO',
  }) async => medicalFieldCatalogTestData(category, locale: locale);
}

MedicalFieldCatalog medicalFieldCatalogTestData(
  MedicalDocumentCategory category, {
  String locale = 'es-CO',
}) {
  return MedicalFieldCatalog(
    catalogVersion: 'test-1',
    locale: locale,
    category: category.wireValue,
    categoryLabel: category.label,
    sections: const [
      MedicalFieldSection(
        key: 'general',
        label: 'Información general',
        order: 10,
      ),
      MedicalFieldSection(key: 'patient', label: 'Paciente', order: 20),
      MedicalFieldSection(key: 'owner', label: 'Tutor', order: 30),
      MedicalFieldSection(key: 'issuer', label: 'Veterinario', order: 40),
      MedicalFieldSection(key: 'vaccinations', label: 'Vacunas', order: 50),
      MedicalFieldSection(
        key: 'additional',
        label: 'Información adicional',
        order: 90,
      ),
    ],
    fields: const [
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
        path: 'issuer.clinic',
        label: 'Clínica',
        sectionKey: 'issuer',
        order: 10,
        kind: MedicalFieldKind.text,
        editable: true,
        hideWhenEmpty: true,
      ),
      MedicalFieldDefinition(
        path: 'vaccinations',
        label: 'Vacuna',
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
    hiddenTechnicalKeys: const {'id', 'confidence', 'source'},
  );
}
