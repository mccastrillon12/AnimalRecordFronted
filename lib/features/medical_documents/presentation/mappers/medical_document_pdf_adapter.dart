import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_field_catalog.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_date_mapper.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_display_formatter.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';

String medicalDocumentSendActionLabel(MedicalDocumentCategory category) {
  return switch (category) {
    MedicalDocumentCategory.prescription => 'Enviar fórmula',
    MedicalDocumentCategory.medicalOrder => 'Enviar orden',
    MedicalDocumentCategory.referral => 'Enviar remisión',
    MedicalDocumentCategory.vaccinationCard => 'Enviar carné',
    MedicalDocumentCategory.clinicalHistory => 'Enviar historia clínica',
    MedicalDocumentCategory.diagnosticImage => 'Enviar imagen diagnóstica',
    MedicalDocumentCategory.laboratoryResult =>
      'Enviar resultado de laboratorio',
    MedicalDocumentCategory.other => 'Enviar archivo',
  };
}

SharedFileAnalysisEntity medicalDocumentToPdfAnalysis({
  required MedicalDocumentEntity document,
  required MedicalFieldCatalog catalog,
}) {
  return medicalDocumentToAnalysis(
    document: document,
    extraction: document.validatedExtraction!,
    catalog: catalog,
    displayCategory:
        document.finalCategory ?? document.validatedExtraction!.documentType,
    includeUncataloguedFields:
        document.finalCategory != document.validatedExtraction!.documentType,
  );
}

/// Converts a canonical extraction into the legacy visual contract.
/// Only fields published by [catalog] are rendered.
SharedFileAnalysisEntity medicalDocumentToAnalysis({
  required MedicalDocumentEntity document,
  required MedicalDocumentExtractionEntity extraction,
  required MedicalFieldCatalog catalog,
  MedicalDocumentCategory? displayCategory,
  bool includeUncataloguedFields = false,
}) {
  final values =
      includeUncataloguedFields && extraction.rawExtraction.isNotEmpty
      ? _losslessExtractionValues(extraction)
      : _extractionValues(extraction);
  final sections = [..._catalogSections(catalog, values)];
  if (includeUncataloguedFields) {
    final uncatalogued = _uncataloguedSection(catalog, values);
    if (uncatalogued != null) sections.add(uncatalogued);
  }
  return SharedFileAnalysisEntity(
    documentType: (displayCategory ?? extraction.documentType).label,
    documentNumber:
        extraction.documentType == MedicalDocumentCategory.vaccinationCard
        ? ''
        : _documentNumber(document.documentCode),
    date: parseMedicalDocumentDate(extraction.documentDate),
    sourceDateText: extraction.documentDate,
    sourceDateLabel: catalog.fieldAt('documentDate')?.label,
    originalFileName: document.originalFileName,
    originalFileNameLabel: 'Archivo original',
    patient: _patient(document, extraction.patient, catalog),
    tutor: _tutor(document, extraction.owner, catalog),
    veterinarian: _veterinarian(extraction.issuer, catalog),
    sections: List.unmodifiable(sections),
  );
}

const _emptyPatient = SharedFilePatientAnalysisEntity(
  name: '',
  recordId: '',
  species: '',
  breed: '',
  age: '',
  weight: '',
);

const _emptyTutor = SharedFileTutorAnalysisEntity(
  name: '',
  identification: '',
  phoneNumber: '',
);

SharedFilePatientAnalysisEntity _patient(
  MedicalDocumentEntity document,
  MedicalDocumentPatientEntity? extractedPatient,
  MedicalFieldCatalog catalog,
) {
  MedicalDocumentAnimalEntity? backendPatient;
  for (final animal in document.animalDetails) {
    if (animal.id.isEmpty || document.animalIds.contains(animal.id)) {
      backendPatient = animal;
      break;
    }
  }
  backendPatient ??= document.animalDetails.isEmpty
      ? null
      : document.animalDetails.first;

  final useBackendFields = backendPatient?.fields.isNotEmpty == true;
  final useExtractedPatient =
      !useBackendFields && (extractedPatient?.hasData ?? false);
  final values = useBackendFields
      ? <String, dynamic>{
          ...backendPatient!.fields,
          'name': backendPatient.name,
          if (backendPatient.code != null) 'identifier': backendPatient.code,
          if (backendPatient.species != null) 'species': backendPatient.species,
          if (backendPatient.breed != null) 'breed': backendPatient.breed,
          if (backendPatient.sex != null) 'sex': backendPatient.sex,
          if (backendPatient.color != null) 'color': backendPatient.color,
          if (backendPatient.birthdate != null)
            'birthDate': backendPatient.birthdate,
          if (backendPatient.age != null) 'age': backendPatient.age,
          if (backendPatient.weight != null) 'weight': backendPatient.weight,
        }
      : useExtractedPatient
      ? _patientValues(extractedPatient!)
      : <String, dynamic>{
          if (backendPatient != null) ...{
            'name': backendPatient.name,
            if (backendPatient.code != null) 'identifier': backendPatient.code,
            if (backendPatient.species != null)
              'species': backendPatient.species,
            if (backendPatient.breed != null) 'breed': backendPatient.breed,
            if (backendPatient.sex != null) 'sex': backendPatient.sex,
            if (backendPatient.color != null) 'color': backendPatient.color,
            if (backendPatient.birthdate != null)
              'birthDate': backendPatient.birthdate,
            if (backendPatient.age != null) 'age': backendPatient.age,
            if (backendPatient.weight != null) 'weight': backendPatient.weight,
            ...backendPatient.additionalDetails,
          },
        };
  final name = medicalDocumentDisplayValue(values['name']);

  return SharedFilePatientAnalysisEntity(
    name: name,
    recordId: '',
    species: '',
    breed: '',
    age: '',
    weight: '',
    additionalDetails: _partyDetails('patient', values, catalog),
  );
}

SharedFileTutorAnalysisEntity _tutor(
  MedicalDocumentEntity document,
  MedicalDocumentOwnerEntity? extractedOwner,
  MedicalFieldCatalog catalog,
) {
  final backendTutor = document.tutorDetails;
  final values = extractedOwner != null
      ? <String, dynamic>{
          if (extractedOwner.name != null) 'name': extractedOwner.name,
          if (extractedOwner.identification != null)
            'identification': extractedOwner.identification,
          if (extractedOwner.phone != null) 'phone': extractedOwner.phone,
          if (extractedOwner.email != null) 'email': extractedOwner.email,
          if (extractedOwner.address != null) 'address': extractedOwner.address,
        }
      : <String, dynamic>{
          if (backendTutor != null) ...{
            ...backendTutor.fields,
            'name': backendTutor.name,
            'identification': backendTutor.identification,
            'phone': backendTutor.phoneNumber,
            ...backendTutor.additionalDetails,
          },
        };
  return SharedFileTutorAnalysisEntity(
    name: medicalDocumentDisplayValue(values['name']),
    identification: '',
    phoneNumber: '',
    additionalDetails: _partyDetails('owner', values, catalog),
  );
}

SharedFileVeterinarianAnalysisEntity? _veterinarian(
  Map<String, dynamic>? issuer,
  MedicalFieldCatalog catalog,
) {
  if (issuer == null || issuer.isEmpty) return null;
  final nested = issuer['veterinarian'];
  final values = nested is Map
      ? nested.map((key, value) => MapEntry(key.toString(), value))
      : issuer;
  final result = SharedFileVeterinarianAnalysisEntity(
    name: medicalDocumentDisplayValue(values['name']),
    clinic: '',
    professionalId: '',
    additionalDetails: _partyDetails('issuer', values, catalog),
  );
  return result.hasData ? result : null;
}

List<SharedFileAnalysisDetailEntity> _partyDetails(
  String pathPrefix,
  Map<String, dynamic> values,
  MedicalFieldCatalog catalog,
) {
  final fields =
      catalog.fields
          .where((field) => field.path.startsWith('$pathPrefix.'))
          .where((field) => field.path != '$pathPrefix.name')
          .where(
            (field) => !isMedicalDocumentTechnicalPath(
              field.path,
              catalog.hiddenTechnicalKeys,
            ),
          )
          .toList(growable: false)
        ..sort((left, right) => left.order.compareTo(right.order));
  return [
    for (final field in fields)
      if (_readPath(values, field.path.substring(pathPrefix.length + 1))
          case final value?)
        if (!field.hideWhenEmpty || !_isEmpty(value))
          SharedFileAnalysisDetailEntity(
            label: field.label,
            value: medicalDocumentDisplayValue(
              value,
              hiddenTechnicalKeys: catalog.hiddenTechnicalKeys,
            ),
          ),
  ];
}

Map<String, dynamic> _patientValues(MedicalDocumentPatientEntity patient) {
  return {
    if (patient.name != null) 'name': patient.name,
    if (patient.identifier != null) 'identifier': patient.identifier,
    if (patient.species != null) 'species': patient.species,
    if (patient.breed != null) 'breed': patient.breed,
    if (patient.sex != null) 'sex': patient.sex,
    if (patient.color != null) 'color': patient.color,
    if (patient.size != null) 'size': patient.size,
    if (patient.reproductiveStatus != null)
      'reproductiveStatus': patient.reproductiveStatus,
    if (patient.age != null) 'age': patient.age,
    if (patient.birthDate != null) 'birthDate': patient.birthDate,
    if (patient.weight != null) 'weight': patient.weight,
    if (patient.microchip != null) 'microchip': patient.microchip,
    ...patient.fields,
  };
}

String _documentNumber(String documentCode) {
  final value = documentCode.trim();
  if (value.isEmpty) return '';
  return value.startsWith('N°') ? value : 'N° $value';
}

List<SharedFileAnalysisSectionEntity> _catalogSections(
  MedicalFieldCatalog catalog,
  Map<String, dynamic> extraction,
) {
  final orderedSections = [...catalog.sections]
    ..sort((left, right) => left.order.compareTo(right.order));
  final result = <SharedFileAnalysisSectionEntity>[];

  for (final section in orderedSections) {
    final fields =
        catalog.fields
            .where((field) => field.sectionKey == section.key)
            .where((field) => field.path != 'documentDate')
            .where((field) => !_isPartyPath(field.path))
            .where(
              (field) => !isMedicalDocumentTechnicalPath(
                field.path,
                catalog.hiddenTechnicalKeys,
              ),
            )
            .toList(growable: false)
          ..sort((left, right) => left.order.compareTo(right.order));
    final scalarDetails = <SharedFileAnalysisDetailEntity>[];
    final repeatedSections = <SharedFileAnalysisSectionEntity>[];

    for (final field in fields) {
      final value = _readPath(extraction, field.path);
      if (field.hideWhenEmpty && _isEmpty(value)) continue;
      switch (field.kind) {
        case MedicalFieldKind.table:
          repeatedSections.addAll(_tableSections(field, value, catalog));
        case MedicalFieldKind.dynamicObject:
          scalarDetails.addAll(_dynamicDetails(field, value, catalog));
        case MedicalFieldKind.text:
        case MedicalFieldKind.longText:
        case MedicalFieldKind.date:
        case MedicalFieldKind.list:
          final text = medicalDocumentDisplayValue(
            value,
            hiddenTechnicalKeys: catalog.hiddenTechnicalKeys,
          );
          if (!field.hideWhenEmpty || text.isNotEmpty) {
            scalarDetails.add(
              SharedFileAnalysisDetailEntity(label: field.label, value: text),
            );
          }
      }
    }

    if (scalarDetails.isNotEmpty) {
      result.add(
        SharedFileAnalysisSectionEntity(
          title: section.label,
          details: scalarDetails,
        ),
      );
    }
    result.addAll(repeatedSections);
  }
  return List.unmodifiable(result);
}

List<SharedFileAnalysisSectionEntity> _tableSections(
  MedicalFieldDefinition field,
  Object? value,
  MedicalFieldCatalog catalog,
) {
  if (value is! Iterable) return const [];
  final rows = value
      .whereType<Map>()
      .map(
        (row) =>
            row.map((key, itemValue) => MapEntry(key.toString(), itemValue)),
      )
      .toList(growable: false);
  if (rows.isEmpty) return const [];

  final columns = [...field.columns]
    ..sort((left, right) => left.order.compareTo(right.order));
  final visibleColumns = columns
      .where((column) {
        if (isMedicalDocumentTechnicalKey(
          column.key,
          catalog.hiddenTechnicalKeys,
        )) {
          return false;
        }
        return !column.hideWhenEmpty ||
            rows.any((row) => !_isEmpty(row[column.key]));
      })
      .toList(growable: false);

  final sections = <SharedFileAnalysisSectionEntity>[];
  for (var index = 0; index < rows.length; index++) {
    final details = <SharedFileAnalysisDetailEntity>[
      for (final column in visibleColumns)
        if (!column.hideWhenEmpty || !_isEmpty(rows[index][column.key]))
          SharedFileAnalysisDetailEntity(
            label: column.label,
            value: medicalDocumentDisplayValue(
              rows[index][column.key],
              hiddenTechnicalKeys: catalog.hiddenTechnicalKeys,
            ),
          ),
    ];
    if (details.isEmpty) continue;
    sections.add(
      SharedFileAnalysisSectionEntity(
        title: rows.length == 1 ? field.label : '${field.label} ${index + 1}',
        details: details,
      ),
    );
  }
  return sections;
}

List<SharedFileAnalysisDetailEntity> _dynamicDetails(
  MedicalFieldDefinition field,
  Object? value,
  MedicalFieldCatalog catalog,
) {
  if (value is! Map) return const [];
  final baseLabel = field.fallbackLabel?.trim().isNotEmpty == true
      ? field.fallbackLabel!.trim()
      : 'Campo adicional';
  final entries = value.entries
      .where(
        (entry) =>
            !isMedicalDocumentTechnicalKey(
              entry.key.toString(),
              catalog.hiddenTechnicalKeys,
            ) &&
            !_isEmpty(entry.value),
      )
      .toList(growable: false);
  return [
    for (var index = 0; index < entries.length; index++)
      SharedFileAnalysisDetailEntity(
        label: entries.length == 1 ? baseLabel : '$baseLabel ${index + 1}',
        value: medicalDocumentDisplayValue(
          entries[index].value,
          hiddenTechnicalKeys: catalog.hiddenTechnicalKeys,
        ),
      ),
  ];
}

Object? _readPath(Map<String, dynamic> values, String path) {
  Object? current = values;
  for (final segment in path.split('.')) {
    if (current is! Map) return null;
    current = current[segment];
  }
  return current;
}

bool _isEmpty(Object? value) {
  if (value == null) return true;
  if (value is String) return value.trim().isEmpty;
  if (value is Iterable) return value.isEmpty;
  if (value is Map) return value.isEmpty;
  return false;
}

bool _isPartyPath(String path) =>
    path.startsWith('patient.') ||
    path.startsWith('owner.') ||
    path.startsWith('issuer.');

Map<String, dynamic> _losslessExtractionValues(
  MedicalDocumentExtractionEntity extraction,
) {
  final values = _deepCopyMap(extraction.rawExtraction);
  values['documentType'] = extraction.documentType.label;
  values['additionalFields'] = _deepCopyMap(extraction.additionalFields);
  return values;
}

SharedFileAnalysisSectionEntity? _uncataloguedSection(
  MedicalFieldCatalog catalog,
  Map<String, dynamic> extraction,
) {
  final uncataloguedValues = <Object?>[];

  void collect(Object? value, List<String> path) {
    final displayPath = path.join('.');
    if (displayPath.isNotEmpty &&
        isMedicalDocumentTechnicalPath(
          displayPath,
          catalog.hiddenTechnicalKeys,
        )) {
      return;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        collect(entry.value, [...path, entry.key.toString()]);
      }
      return;
    }
    if (value is Iterable) {
      final items = value.toList(growable: false);
      if (items.every((item) => item is! Map && item is! Iterable)) {
        if (!_isCataloguedPath(path, catalog) && !_isEmpty(items)) {
          uncataloguedValues.add(items);
        }
        return;
      }
      for (var index = 0; index < items.length; index++) {
        collect(items[index], [...path, '$index']);
      }
      return;
    }
    if (!_isEmpty(value) && !_isCataloguedPath(path, catalog)) {
      uncataloguedValues.add(value);
    }
  }

  collect(extraction, const []);
  if (uncataloguedValues.isEmpty) return null;
  return SharedFileAnalysisSectionEntity(
    title: 'Información adicional extraída',
    details: [
      for (var index = 0; index < uncataloguedValues.length; index++)
        SharedFileAnalysisDetailEntity(
          label: uncataloguedValues.length == 1
              ? 'Campo adicional'
              : 'Campo adicional ${index + 1}',
          value: medicalDocumentDisplayValue(
            uncataloguedValues[index],
            hiddenTechnicalKeys: catalog.hiddenTechnicalKeys,
          ),
        ),
    ],
  );
}

bool _isCataloguedPath(List<String> rawPath, MedicalFieldCatalog catalog) {
  final path = rawPath
      .where((segment) => int.tryParse(segment) == null)
      .join('.');
  if (const {
    'documentType',
    'documentDate',
    'patient.name',
    'owner.name',
    'issuer.name',
  }.contains(path)) {
    return true;
  }
  for (final field in catalog.fields) {
    if (field.kind == MedicalFieldKind.dynamicObject &&
        (path == field.path || path.startsWith('${field.path}.'))) {
      return true;
    }
    if (path == field.path) return true;
    if (field.kind == MedicalFieldKind.table &&
        path.startsWith('${field.path}.')) {
      final columnPath = path.substring(field.path.length + 1);
      if (field.columns.any((column) => column.key == columnPath)) return true;
    }
  }
  return false;
}

Map<String, dynamic> _deepCopyMap(Map<String, dynamic> values) => {
  for (final entry in values.entries) entry.key: _deepCopyValue(entry.value),
};

Object? _deepCopyValue(Object? value) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key.toString(): _deepCopyValue(entry.value),
    };
  }
  if (value is Iterable) {
    return value.map(_deepCopyValue).toList(growable: false);
  }
  return value;
}

Map<String, dynamic> _extractionValues(
  MedicalDocumentExtractionEntity extraction,
) {
  Map<String, dynamic> item(MedicalDocumentItemEntity value) => {
    'id': value.id,
    ...value.fields,
    if (value.confidence != null) 'confidence': value.confidence,
    if (value.source != null)
      'source': {
        if (value.source!.page != null) 'page': value.source!.page,
        if (value.source!.text != null) 'text': value.source!.text,
      },
  };

  Map<String, dynamic>? patient() {
    final value = extraction.patient;
    if (value == null) return null;
    if (value.fields.isNotEmpty) return Map<String, dynamic>.from(value.fields);
    return {
      if (value.name != null) 'name': value.name,
      if (value.identifier != null) 'identifier': value.identifier,
      if (value.species != null) 'species': value.species,
      if (value.breed != null) 'breed': value.breed,
      if (value.sex != null) 'sex': value.sex,
      if (value.color != null) 'color': value.color,
      if (value.size != null) 'size': value.size,
      if (value.reproductiveStatus != null)
        'reproductiveStatus': value.reproductiveStatus,
      if (value.age != null) 'age': value.age,
      if (value.birthDate != null) 'birthDate': value.birthDate,
      if (value.weight != null) 'weight': value.weight,
      if (value.microchip != null) 'microchip': value.microchip,
    };
  }

  Map<String, dynamic>? owner() {
    final value = extraction.owner;
    if (value == null) return null;
    return {
      if (value.name != null) 'name': value.name,
      if (value.identification != null) 'identification': value.identification,
      if (value.phone != null) 'phone': value.phone,
      if (value.email != null) 'email': value.email,
      if (value.address != null) 'address': value.address,
    };
  }

  return {
    ...extraction.preservedUnknownFields,
    'documentType': extraction.documentType.label,
    if (extraction.documentTypeConfidence != null)
      'documentTypeConfidence': extraction.documentTypeConfidence,
    if (extraction.summary != null) 'summary': extraction.summary,
    if (extraction.documentDate != null)
      'documentDate': extraction.documentDate,
    if (extraction.issuer != null) 'issuer': extraction.issuer,
    if (patient() case final value?) 'patient': value,
    if (owner() case final value?) 'owner': value,
    'patientHints': extraction.patientHints,
    'diagnoses': extraction.diagnoses.map(item).toList(growable: false),
    'medications': extraction.medications.map(item).toList(growable: false),
    'vaccinations': extraction.vaccinations.map(item).toList(growable: false),
    'medicalOrders': extraction.medicalOrders.map(item).toList(growable: false),
    if (extraction.clinicalHistory != null)
      'clinicalHistory': extraction.clinicalHistory,
    'diagnosticResults': extraction.diagnosticResults
        .map(item)
        .toList(growable: false),
    if (extraction.referral != null) 'referral': extraction.referral,
    'diagnosticImages': extraction.diagnosticImages
        .map(item)
        .toList(growable: false),
    if (extraction.laboratoryReport != null)
      'laboratoryReport': extraction.laboratoryReport,
    'laboratoryResults': extraction.laboratoryResults
        .map(item)
        .toList(growable: false),
    'additionalFields': extraction.additionalFields,
    'warnings': extraction.warnings,
  };
}
