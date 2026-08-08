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
  final patient = _patient(document, extraction);
  final tutor = document.tutorDetails;
  return SharedFileAnalysisEntity(
    documentType:
        document.finalCategory?.label ?? extraction.documentType.label,
    documentNumber: _documentNumber(document.id),
    date: parseMedicalDocumentDate(extraction.documentDate),
    sourceDateText: extraction.documentDate,
    originalFileName: document.originalFileName,
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
    tutor: SharedFileTutorAnalysisEntity(
      name: tutor?.name ?? '',
      identification: tutor?.identification ?? '',
      phoneNumber: tutor?.phoneNumber ?? '',
      additionalDetails: _analysisDetails(tutor?.additionalDetails ?? const {}),
    ),
    veterinarian: _veterinarian(extraction.issuer),
    itemsTitle: _itemsTitle(extraction.documentType),
    medications: _visibleItems(extraction)
        .where((item) => item.fields.values.any(_hasValue))
        .map(
          (item) => SharedFileMedicationAnalysisEntity(
            name: item.name,
            quantity: _quantity(item.fields['quantity']),
            instructions: _instructions(item.fields),
            originalUrl: document.id,
          ),
        )
        .toList(growable: false),
    observations: _observations(extraction),
  );
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
  MedicalDocumentExtractionEntity extraction,
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

  final hints = extraction.patientHints;
  final backendName = backendAnimal?.name.trim() ?? '';
  final backendSpecies = backendAnimal?.species?.trim() ?? '';
  final backendBreed = backendAnimal?.breed?.trim() ?? '';
  final backendSex = backendAnimal?.sex?.trim() ?? '';
  final backendColor = backendAnimal?.color?.trim() ?? '';
  final backendAge = backendAnimal?.age?.trim() ?? '';
  final backendWeight = backendAnimal?.weight?.trim() ?? '';
  final additionalDetails = <SharedFileAnalysisDetailEntity>[
    if (backendAnimal?.birthdate?.trim().isNotEmpty == true)
      SharedFileAnalysisDetailEntity(
        label: 'Fecha de nacimiento',
        value: backendAnimal!.birthdate!.trim(),
      ),
    ..._analysisDetails(backendAnimal?.additionalDetails ?? const {}),
    for (var index = 7; index < hints.length; index++)
      if (hints[index].trim().isNotEmpty)
        SharedFileAnalysisDetailEntity(
          label: 'Información adicional ${index - 6}',
          value: hints[index].trim(),
        ),
  ];
  return (
    name: backendName.isNotEmpty ? backendName : _hint(hints, 0) ?? '',
    code: backendAnimal?.code?.trim().isNotEmpty == true
        ? backendAnimal!.code!.trim()
        : '',
    species: backendSpecies.isNotEmpty ? backendSpecies : _hint(hints, 1) ?? '',
    breed: backendBreed.isNotEmpty ? backendBreed : _hint(hints, 2) ?? '',
    sex: backendSex.isNotEmpty ? backendSex : _hint(hints, 3) ?? '',
    color: backendColor.isNotEmpty ? backendColor : _hint(hints, 4) ?? '',
    age: backendAge.isNotEmpty ? backendAge : _hint(hints, 6) ?? '',
    weight: backendWeight.isNotEmpty ? backendWeight : _hint(hints, 5) ?? '',
    additionalDetails: additionalDetails,
  );
}

String? _hint(List<String> hints, int index) {
  if (index >= hints.length || hints[index].trim().isEmpty) return null;
  return hints[index].trim();
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
  MedicalDocumentCategory.medicalOrder => 'Órdenes médicas',
  MedicalDocumentCategory.referral => 'Información médica',
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
  final clinic = _firstValue(values, const [
    'clinic',
    'clinicName',
    'institution',
    'institutionName',
  ]);
  final professionalId = _firstValue(values, const [
    'professionalId',
    'professionalLicense',
    'professionalCard',
    'licenseNumber',
    'registrationNumber',
    'registration',
  ]);
  final additionalDetails = _analysisDetails(
    {
      for (final entry in values.entries)
        if (_hasValue(entry.value)) entry.key: _displayValue(entry.value),
    },
    excludedKeys: const {
      'name',
      'fullName',
      'veterinarianName',
      'doctorName',
      'clinic',
      'clinicName',
      'institution',
      'institutionName',
      'professionalId',
      'professionalLicense',
      'professionalCard',
      'licenseNumber',
      'registrationNumber',
      'registration',
    },
  );
  if (name.isEmpty &&
      clinic.isEmpty &&
      professionalId.isEmpty &&
      additionalDetails.isEmpty) {
    return null;
  }
  return SharedFileVeterinarianAnalysisEntity(
    name: name,
    clinic: clinic,
    professionalId: professionalId,
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
          label: _fieldLabel(entry.key),
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
            _hasValue(entry.value),
      )
      .map((entry) {
        final value = _displayValue(entry.value);
        return '${_fieldLabel(entry.key)}: $value';
      })
      .join('\n');
}

String? _observations(MedicalDocumentExtractionEntity extraction) {
  final values = <String>[
    if (extraction.summary?.trim().isNotEmpty ?? false) extraction.summary!,
    ...extraction.diagnoses
        .map((diagnosis) => _itemText('Diagnóstico', diagnosis))
        .where((value) => value.isNotEmpty),
    ..._mapValues(extraction.clinicalHistory),
    ..._mapValues(extraction.referral),
    ..._mapValues(extraction.additionalFields),
    ...extraction.warnings.map((warning) => 'Advertencia: $warning'),
  ];
  return values.isEmpty ? null : values.join('\n');
}

Iterable<String> _mapValues(Map<String, dynamic>? values) sync* {
  if (values == null) return;
  for (final entry in values.entries) {
    if (_isStructuredPartyKey(entry.key)) continue;
    if (_hasValue(entry.value)) {
      yield '${_fieldLabel(entry.key)}: ${_displayValue(entry.value)}';
    }
  }
}

const _structuredPartyKeys = {
  'source',
  'confidence',
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

String _itemText(String prefix, MedicalDocumentItemEntity item) {
  final values = item.fields.entries
      .where((entry) => _hasValue(entry.value))
      .map(
        (entry) => '${_fieldLabel(entry.key)}: ${_displayValue(entry.value)}',
      )
      .join(' · ');
  return values.isEmpty ? '' : '$prefix — $values';
}

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
          entry.key != 'source' &&
          entry.key != 'confidence' &&
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
              entry.key != 'source' &&
              entry.key != 'confidence' &&
              _hasValue(entry.value),
        )
        .map(
          (entry) =>
              '${_fieldLabel(entry.key.toString())}: '
              '${_displayValue(entry.value)}',
        )
        .join(', ');
  }
  return value?.toString().trim() ?? '';
}

String _fieldLabel(String value) {
  const labels = {
    'activeIngredient': 'Principio activo',
    'address': 'Dirección',
    'anamnesis': 'Anamnesis',
    'applicationDate': 'Fecha de aplicación',
    'applicationSite': 'Sitio de aplicación',
    'brand': 'Marca',
    'clinicalFindings': 'Hallazgos clínicos',
    'clinicalSummary': 'Resumen clínico',
    'color': 'Color',
    'code': 'Código',
    'destination': 'Destino',
    'dose': 'Dosis',
    'duration': 'Duración',
    'evolution': 'Evolución',
    'followUp': 'Seguimiento',
    'frequency': 'Frecuencia',
    'instructions': 'Indicaciones',
    'interpretation': 'Interpretación',
    'lot': 'Lote',
    'manufacturer': 'Fabricante',
    'email': 'Correo electrónico',
    'name': 'Nombre',
    'nextDoseDate': 'Próxima dosis',
    'notes': 'Notas',
    'orderType': 'Tipo de orden',
    'physicalExam': 'Examen físico',
    'presentation': 'Presentación',
    'priority': 'Prioridad',
    'prognosis': 'Pronóstico',
    'quantity': 'Cantidad',
    'reason': 'Motivo',
    'reasonForConsultation': 'Motivo de consulta',
    'recommendations': 'Recomendaciones',
    'result': 'Resultado',
    'route': 'Vía',
    'sex': 'Sexo',
    'specialty': 'Especialidad',
    'status': 'Estado',
    'treatmentPlan': 'Plan de tratamiento',
    'veterinarian': 'Veterinario',
    'vitalSigns': 'Signos vitales',
  };
  final label = labels[value];
  if (label != null) return label;
  final spaced = value.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  if (spaced.isEmpty) return 'Campo';
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}
