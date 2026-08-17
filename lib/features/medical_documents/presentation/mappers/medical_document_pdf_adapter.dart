import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_date_mapper.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';

String medicalDocumentSendActionLabel(MedicalDocumentCategory category) {
  return switch (category) {
    MedicalDocumentCategory.prescription => 'Enviar fórmula',
    MedicalDocumentCategory.medicalOrder => 'Enviar orden',
    MedicalDocumentCategory.referral => 'Enviar remisión',
    MedicalDocumentCategory.vaccinationCard => 'Enviar carné',
    MedicalDocumentCategory.clinicalHistory => 'Enviar historia clínica',
    MedicalDocumentCategory.other => 'Enviar documento',
  };
}

SharedFileAnalysisEntity medicalDocumentToPdfAnalysis({
  required MedicalDocumentEntity document,
}) {
  final extraction = document.validatedExtraction!;
  return medicalDocumentToAnalysis(document: document, extraction: extraction);
}

SharedFileAnalysisEntity medicalDocumentToAnalysis({
  required MedicalDocumentEntity document,
  required MedicalDocumentExtractionEntity extraction,
}) {
  final patient = _patient(document, extraction.patient);
  final tutor = _tutor(
    extraction.owner == null
        ? document.tutorDetails
        : _ownerAsTutor(extraction.owner!),
  );
  return SharedFileAnalysisEntity(
    documentType:
        document.finalCategory?.label ?? extraction.documentType.label,
    documentNumber: _documentNumber(document.id),
    date: parseMedicalDocumentDate(extraction.documentDate),
    sourceDateText: extraction.documentDate,
    sourceDateLabel: _displayKey('documentDate'),
    originalFileName: document.originalFileName,
    originalFileNameLabel: _displayKey('originalFileName'),
    patient: SharedFilePatientAnalysisEntity(
      name: patient.name,
      recordId: patient.code,
      species: patient.species,
      breed: patient.breed,
      sex: patient.sex,
      color: patient.color,
      age: patient.age,
      weight: patient.weight,
      additionalDetails: patient.additionalDetails,
    ),
    tutor: tutor,
    veterinarian: _veterinarian(extraction.issuer),
    itemsTitle: _itemsTitle(extraction.documentType),
    medications: _visibleItems(extraction)
        .where(_itemHasValue)
        .map(
          (item) => SharedFileMedicationAnalysisEntity(
            name: item.name,
            quantity: _quantity(item.fields['quantity']),
            instructions:
                extraction.documentType ==
                    MedicalDocumentCategory.vaccinationCard
                ? ''
                : _instructions(_itemValues(item)),
            details:
                extraction.documentType ==
                    MedicalDocumentCategory.vaccinationCard
                ? _rawItemDetails(_itemValues(item))
                : const [],
            originalUrl: document.id,
          ),
        )
        .toList(growable: false),
    sections: _structuredSections(extraction),
    observations: null,
  );
}

SharedFileTutorAnalysisEntity _tutor(MedicalDocumentTutorEntity? tutor) {
  if (tutor == null) {
    return const SharedFileTutorAnalysisEntity(
      name: '',
      identification: '',
      phoneNumber: '',
    );
  }
  if (tutor.fields.isNotEmpty) {
    return SharedFileTutorAnalysisEntity(
      name: tutor.name,
      identification: '',
      phoneNumber: '',
      additionalDetails: tutor.fields.entries
          .where(
            (entry) =>
                !_isTutorNameKey(entry.key) && entry.value.trim().isNotEmpty,
          )
          .map(
            (entry) => SharedFileAnalysisDetailEntity(
              label: _displayKey(entry.key),
              value: entry.value.trim(),
            ),
          )
          .toList(growable: false),
    );
  }
  return SharedFileTutorAnalysisEntity(
    name: tutor.name,
    identification: tutor.identification,
    phoneNumber: tutor.phoneNumber,
    additionalDetails: _analysisDetails(tutor.additionalDetails),
  );
}

MedicalDocumentTutorEntity _ownerAsTutor(MedicalDocumentOwnerEntity owner) {
  return MedicalDocumentTutorEntity(
    name: owner.name ?? '',
    identification: owner.identification ?? '',
    phoneNumber: owner.phone ?? '',
    additionalDetails: {
      if (owner.email?.trim().isNotEmpty == true) 'email': owner.email!.trim(),
      if (owner.address?.trim().isNotEmpty == true)
        'address': owner.address!.trim(),
    },
  );
}

bool _isTutorNameKey(String key) {
  final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return const {
    'name',
    'fullname',
    'owner',
    'ownername',
    'tutor',
    'tutorname',
    'guardian',
    'guardianname',
    'proprietor',
    'proprietorname',
  }.contains(normalized);
}

String _documentNumber(String id) {
  final value = id.trim();
  if (value.isEmpty) return '';
  return 'N° ${value.length > 8 ? value.substring(0, 8) : value}';
}

({
  String name,
  String code,
  String species,
  String breed,
  String sex,
  String color,
  String age,
  String weight,
  List<SharedFileAnalysisDetailEntity> additionalDetails,
})
_patient(
  MedicalDocumentEntity document,
  MedicalDocumentPatientEntity? structuredPatient,
) {
  MedicalDocumentAnimalEntity? backendAnimal;
  for (final animal in document.animalDetails) {
    if (animal.id.isEmpty || document.animalIds.contains(animal.id)) {
      backendAnimal = animal;
      break;
    }
  }
  backendAnimal ??= document.animalDetails.isEmpty
      ? null
      : document.animalDetails.first;

  final backendName = backendAnimal?.name.trim() ?? '';
  final backendFields = backendAnimal?.fields ?? const <String, String>{};
  if (backendFields.isNotEmpty) {
    return (
      name: backendName,
      code: '',
      species: '',
      breed: '',
      sex: '',
      color: '',
      age: '',
      weight: '',
      additionalDetails: backendFields.entries
          .where(
            (entry) =>
                !_isPatientNameKey(entry.key) && entry.value.trim().isNotEmpty,
          )
          .map(
            (entry) => SharedFileAnalysisDetailEntity(
              label: _displayKey(entry.key),
              value: entry.value.trim(),
            ),
          )
          .toList(growable: false),
    );
  }

  if (structuredPatient?.hasData ?? false) {
    final fields = structuredPatient!.fields;
    return (
      name: structuredPatient.name?.trim() ?? '',
      code: '',
      species: '',
      breed: '',
      sex: '',
      color: '',
      age: '',
      weight: '',
      additionalDetails: fields.entries
          .where(
            (entry) =>
                !_isPatientNameKey(entry.key) && entry.value.trim().isNotEmpty,
          )
          .map(
            (entry) => SharedFileAnalysisDetailEntity(
              label: _displayKey(entry.key),
              value: entry.value.trim(),
            ),
          )
          .toList(growable: false),
    );
  }
  final additionalDetails = <SharedFileAnalysisDetailEntity>[
    ..._analysisDetails(backendAnimal?.additionalDetails ?? const {}),
  ];
  return (
    name: backendName,
    code: '',
    species: '',
    breed: '',
    sex: '',
    color: '',
    age: '',
    weight: '',
    additionalDetails: additionalDetails,
  );
}

bool _isPatientNameKey(String key) {
  final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return const {
    'name',
    'fullname',
    'animal',
    'animalname',
    'patient',
    'patientname',
  }.contains(normalized);
}

List<MedicalDocumentItemEntity> _visibleItems(
  MedicalDocumentExtractionEntity extraction,
) => switch (extraction.documentType) {
  MedicalDocumentCategory.prescription => extraction.medications,
  MedicalDocumentCategory.medicalOrder => extraction.medicalOrders,
  MedicalDocumentCategory.referral => [
    ...extraction.medications,
    ...extraction.diagnosticResults,
  ],
  MedicalDocumentCategory.vaccinationCard => extraction.vaccinations,
  MedicalDocumentCategory.clinicalHistory => extraction.diagnosticResults,
  MedicalDocumentCategory.other => const [],
};

String? _itemsTitle(MedicalDocumentCategory category) => switch (category) {
  MedicalDocumentCategory.prescription => 'Medicamentos',
  MedicalDocumentCategory.medicalOrder => 'Procedimientos',
  MedicalDocumentCategory.referral => 'Resultados diagnósticos',
  MedicalDocumentCategory.vaccinationCard => 'Vacunas',
  MedicalDocumentCategory.clinicalHistory => 'Resultados diagnósticos',
  MedicalDocumentCategory.other => null,
};

SharedFileVeterinarianAnalysisEntity? _veterinarian(
  Map<String, dynamic>? issuer,
) {
  if (issuer == null || issuer.isEmpty) return null;
  final nested = issuer['veterinarian'];
  final values = nested is Map
      ? nested.map((key, value) => MapEntry(key.toString(), value))
      : issuer;
  final name = _firstValue(values, const [
    'name',
    'fullName',
    'veterinarianName',
    'doctorName',
  ]);
  final additionalDetails = _analysisDetails(
    {
      for (final entry in values.entries)
        if (_hasValue(entry.value)) entry.key: _displayValue(entry.value),
    },
    excludedKeys: const {'name', 'fullName', 'veterinarianName', 'doctorName'},
  );
  if (name.isEmpty && additionalDetails.isEmpty) {
    return null;
  }
  return SharedFileVeterinarianAnalysisEntity(
    name: name,
    clinic: '',
    professionalId: '',
    additionalDetails: additionalDetails,
  );
}

List<SharedFileAnalysisDetailEntity> _analysisDetails(
  Map<String, String> values, {
  Set<String> excludedKeys = const {},
}) {
  return values.entries
      .where(
        (entry) =>
            !excludedKeys.contains(entry.key) && entry.value.trim().isNotEmpty,
      )
      .map(
        (entry) => SharedFileAnalysisDetailEntity(
          label: _displayKey(entry.key),
          value: entry.value.trim(),
        ),
      )
      .toList(growable: false);
}

String _firstValue(Map<String, dynamic> values, List<String> keys) {
  for (final key in keys) {
    final value = values[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _instructions(Map<String, dynamic> fields) {
  final parsedQuantity = _quantity(fields['quantity']);
  return fields.entries
      .where(
        (entry) =>
            entry.key != 'name' &&
            (entry.key != 'quantity' || parsedQuantity == null) &&
            !_isWarningKey(entry.key) &&
            !_isSourceKey(entry.key) &&
            _hasValue(entry.value),
      )
      .map((entry) {
        final value = _displayValue(entry.value);
        return '${_displayKey(entry.key)}: $value';
      })
      .join('\n');
}

List<SharedFileAnalysisSectionEntity> _structuredSections(
  MedicalDocumentExtractionEntity extraction,
) {
  final sections = <SharedFileAnalysisSectionEntity>[
    for (var index = 0; index < extraction.diagnoses.length; index++)
      SharedFileAnalysisSectionEntity(
        title: extraction.diagnoses.length == 1
            ? 'Diagnoses'
            : 'Diagnoses ${index + 1}',
        details: _detailsFromMap(_itemValues(extraction.diagnoses[index])),
      ),
    if (_hasValue(extraction.clinicalHistory))
      SharedFileAnalysisSectionEntity(
        title: 'Clinical History',
        details: _detailsFromMap(extraction.clinicalHistory!),
      ),
    if (_hasValue(extraction.referral))
      SharedFileAnalysisSectionEntity(
        title: 'Referral',
        details: _detailsFromMap(extraction.referral!),
      ),
    ..._additionalFieldSections(
      extraction.additionalFields,
      allowedStructuredKeys: {
        if (extraction.diagnoses.isEmpty) 'diagnoses',
        if (extraction.medications.isEmpty) 'medications',
        if (extraction.vaccinations.isEmpty) 'vaccinations',
        if (extraction.medicalOrders.isEmpty) 'medicalOrders',
        if (extraction.clinicalHistory == null) 'clinicalHistory',
        if (extraction.diagnosticResults.isEmpty) 'diagnosticResults',
        if (extraction.referral == null) 'referral',
      },
    ),
  ];
  return sections.where((section) => section.hasData).toList(growable: false);
}

List<SharedFileAnalysisSectionEntity> _additionalFieldSections(
  Map<String, dynamic> values, {
  Set<String> allowedStructuredKeys = const {},
}) {
  final sections = <SharedFileAnalysisSectionEntity>[];
  final scalarDetails = <SharedFileAnalysisDetailEntity>[];

  for (final entry in values.entries) {
    if (_isWarningKey(entry.key) ||
        _isSourceKey(entry.key) ||
        (_isStructuredExtractionKey(entry.key) &&
            !allowedStructuredKeys.contains(entry.key)) ||
        !_hasValue(entry.value)) {
      continue;
    }
    final value = entry.value;
    if (value is Map) {
      final details = _detailsFromMap(
        value.map((key, item) => MapEntry(key.toString(), item)),
      );
      if (details.isNotEmpty) {
        sections.add(
          SharedFileAnalysisSectionEntity(
            title: _displayKey(entry.key),
            details: details,
          ),
        );
      }
      continue;
    }
    if (value is Iterable && value.whereType<Map>().isNotEmpty) {
      var index = 0;
      for (final item in value.whereType<Map>()) {
        final details = _detailsFromMap(
          item.map((key, itemValue) => MapEntry(key.toString(), itemValue)),
        );
        if (details.isEmpty) continue;
        index++;
        sections.add(
          SharedFileAnalysisSectionEntity(
            title: '${_displayKey(entry.key)} $index',
            details: details,
          ),
        );
      }
      continue;
    }
    scalarDetails.add(
      SharedFileAnalysisDetailEntity(
        label: _displayKey(entry.key),
        value: _displayValue(value),
      ),
    );
  }

  if (scalarDetails.isNotEmpty) {
    sections.add(
      SharedFileAnalysisSectionEntity(
        title: 'Información adicional',
        details: scalarDetails,
      ),
    );
  }
  return sections;
}

List<SharedFileAnalysisDetailEntity> _detailsFromMap(
  Map<String, dynamic> values,
) {
  return values.entries
      .where(
        (entry) =>
            !_isWarningKey(entry.key) &&
            !_isSourceKey(entry.key) &&
            !_isStructuredPartyKey(entry.key) &&
            _hasValue(entry.value),
      )
      .map(
        (entry) => SharedFileAnalysisDetailEntity(
          label: _displayKey(entry.key),
          value: _displayValue(entry.value),
        ),
      )
      .toList(growable: false);
}

List<SharedFileAnalysisDetailEntity> _rawItemDetails(
  Map<String, dynamic> values,
) {
  return values.entries
      .where(
        (entry) =>
            entry.key != 'name' &&
            entry.key != 'quantity' &&
            !_isWarningKey(entry.key) &&
            !_isSourceKey(entry.key) &&
            _hasValue(entry.value),
      )
      .map(
        (entry) => SharedFileAnalysisDetailEntity(
          label: _displayKey(entry.key),
          value: _rawDisplayValue(entry.value),
        ),
      )
      .toList(growable: false);
}

String _rawDisplayValue(Object? value) {
  if (value is Iterable) {
    return value.where(_hasValue).map(_rawDisplayValue).join(', ');
  }
  if (value is Map) {
    return value.entries
        .where(
          (entry) =>
              !_isWarningKey(entry.key.toString()) &&
              !_isSourceKey(entry.key.toString()) &&
              _hasValue(entry.value),
        )
        .map(
          (entry) =>
              '${_displayKey(entry.key.toString())}: '
              '${_rawDisplayValue(entry.value)}',
        )
        .join(', ');
  }
  return value?.toString().trim() ?? '';
}

bool _isStructuredExtractionKey(String key) {
  if (_isStructuredPartyKey(key)) return true;
  return const {
    'summary',
    'documentDate',
    'documentType',
    'diagnoses',
    'medications',
    'vaccinations',
    'medicalOrders',
    'clinicalHistory',
    'diagnosticResults',
    'referral',
    'warnings',
  }.contains(key);
}

const _structuredPartyKeys = {
  'patient',
  'patientDetails',
  'animal',
  'animalDetails',
  'patientName',
  'animalName',
  'animalRecordId',
  'animalRecordCode',
  'species',
  'family',
  'breed',
  'race',
  'sex',
  'gender',
  'patientSex',
  'color',
  'coatColor',
  'patientColor',
  'birthdate',
  'birthDate',
  'dateOfBirth',
  'age',
  'weight',
  'tutor',
  'tutorDetails',
  'owner',
  'ownerDetails',
  'guardian',
  'guardianDetails',
  'issuer',
  'veterinarian',
  'veterinarianDetails',
};

bool _isStructuredPartyKey(String key) {
  if (_structuredPartyKeys.contains(key)) return true;
  final normalized = key.toLowerCase();
  return normalized.contains('owner') ||
      normalized.contains('tutor') ||
      normalized.contains('guardian') ||
      normalized.contains('proprietor') ||
      normalized.contains('propietario') ||
      normalized.contains('responsable') ||
      normalized.contains('caregiver');
}

bool _isWarningKey(String key) => key.trim().toLowerCase() == 'warnings';

bool _isSourceKey(String key) => key.trim().toLowerCase() == 'source';

bool _itemHasValue(MedicalDocumentItemEntity item) =>
    item.fields.values.any(_hasValue);

Map<String, dynamic> _itemValues(MedicalDocumentItemEntity item) => {
  if (item.id.trim().isNotEmpty) 'id': item.id,
  ...item.fields,
  if (item.confidence != null) 'confidence': item.confidence,
  if (item.source != null)
    'source': {
      if (item.source!.page != null) 'page': item.source!.page,
      if (item.source!.text != null) 'text': item.source!.text,
    },
};

int? _quantity(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString().trim() ?? '');
}

bool _hasValue(Object? value) {
  if (value == null) return false;
  if (value is String) return value.trim().isNotEmpty;
  if (value is Iterable) return value.any(_hasValue);
  if (value is Map) {
    return value.entries.any(
      (entry) =>
          !_isWarningKey(entry.key.toString()) &&
          !_isSourceKey(entry.key.toString()) &&
          _hasValue(entry.value),
    );
  }
  return true;
}

String _displayValue(Object? value) {
  if (value is Iterable) {
    return value.where(_hasValue).map(_displayValue).join(', ');
  }
  if (value is Map) {
    return value.entries
        .where(
          (entry) =>
              !_isWarningKey(entry.key.toString()) &&
              !_isSourceKey(entry.key.toString()) &&
              _hasValue(entry.value),
        )
        .map(
          (entry) =>
              '${_displayKey(entry.key.toString())}: '
              '${_displayValue(entry.value)}',
        )
        .join(', ');
  }
  return value?.toString().trim() ?? '';
}

String _displayKey(String value) {
  final separated = value
      .trim()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      );
  if (separated.isEmpty) return value;
  return '${separated[0].toUpperCase()}${separated.substring(1)}';
}
