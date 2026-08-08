import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:animal_record/features/medical_documents/data/models/medical_document_text_normalizer.dart';

class MedicalDocumentModel extends MedicalDocumentEntity {
  const MedicalDocumentModel({
    required super.id,
    required super.animalIds,
    required super.originalFileName,
    required super.mimeType,
    required super.fileSize,
    required super.status,
    super.requestedCategory,
    super.primaryDetectedCategory,
    super.detectedCategories,
    super.classificationOutcome,
    super.extractionsByCategory,
    super.finalCategory,
    super.validatedExtraction,
    super.assignments,
    super.animalDetails,
    super.tutorDetails,
    required super.version,
    super.createdAt,
    super.updatedAt,
    super.reviewedAt,
  });

  factory MedicalDocumentModel.fromJson(Map<String, dynamic> json) {
    final extractions =
        <MedicalDocumentCategory, MedicalDocumentExtractionEntity>{};
    final rawExtractions = _map(json['extractionsByCategory']);
    for (final entry in rawExtractions.entries) {
      final category = MedicalDocumentCategory.tryParse(entry.key);
      final extractionJson = _nullableMap(entry.value);
      if (category != null && extractionJson != null) {
        extractions[category] = extractionFromJson(extractionJson, category);
      }
    }

    final validatedJson = _nullableMap(json['validatedExtraction']);
    final finalCategory = MedicalDocumentCategory.tryParse(
      json['finalCategory'],
    );

    return MedicalDocumentModel(
      id: json['id']?.toString() ?? '',
      animalIds: _strings(json['animalIds']),
      originalFileName: normalizeMedicalDocumentFileName(
        json['originalFileName'],
      ),
      mimeType: json['mimeType']?.toString() ?? '',
      fileSize: _integer(json['fileSize']),
      status: MedicalDocumentStatus.parse(json['status']),
      requestedCategory: MedicalDocumentCategory.tryParse(
        json['requestedCategory'],
      ),
      primaryDetectedCategory: MedicalDocumentCategory.tryParse(
        json['primaryDetectedCategory'],
      ),
      detectedCategories: _list(json['detectedCategories'])
          .map(_nullableMap)
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final category = MedicalDocumentCategory.tryParse(item['category']);
            if (category == null) return null;
            return DetectedMedicalDocumentCategoryEntity(
              category: category,
              confidence: _double(item['confidence']),
              pageStart: _nullableInteger(item['pageStart']),
              pageEnd: _nullableInteger(item['pageEnd']),
              summary: item['summary']?.toString(),
              evidence: item['evidence']?.toString(),
            );
          })
          .whereType<DetectedMedicalDocumentCategoryEntity>()
          .toList(growable: false),
      classificationOutcome: MedicalDocumentClassificationOutcome.tryParse(
        json['classificationOutcome'],
      ),
      extractionsByCategory: extractions,
      finalCategory: finalCategory,
      validatedExtraction: validatedJson == null
          ? null
          : extractionFromJson(
              validatedJson,
              finalCategory ??
                  MedicalDocumentCategory.tryParse(
                    validatedJson['documentType'],
                  ) ??
                  MedicalDocumentCategory.other,
            ),
      assignments: _list(json['assignments'])
          .map(_nullableMap)
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => MedicalDocumentAssignmentEntity(
              animalId: item['animalId']?.toString() ?? '',
              extractedItemIds: _strings(item['extractedItemIds']),
            ),
          )
          .toList(growable: false),
      animalDetails: _animalDetails(json),
      tutorDetails: _tutorDetails(json),
      version: _integer(json['version'], fallback: 1),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      reviewedAt: _date(json['reviewedAt']),
    );
  }

  static MedicalDocumentExtractionEntity extractionFromJson(
    Map<String, dynamic> json,
    MedicalDocumentCategory fallbackCategory,
  ) {
    final additionalFields = _map(json['additionalFields']);
    List<MedicalDocumentItemEntity> items(Object? value) => _list(value)
        .map(_nullableMap)
        .whereType<Map<String, dynamic>>()
        .map(_itemFromJson)
        .toList(growable: false);

    return MedicalDocumentExtractionEntity(
      documentType:
          MedicalDocumentCategory.tryParse(json['documentType']) ??
          fallbackCategory,
      documentTypeConfidence: _double(json['documentTypeConfidence']),
      summary: json['summary']?.toString(),
      documentDate: json['documentDate']?.toString(),
      issuer: _nullableMap(
        json['issuer'] ??
            json['veterinarian'] ??
            json['veterinarianDetails'] ??
            json['doctor'] ??
            additionalFields['issuer'] ??
            additionalFields['veterinarian'] ??
            additionalFields['veterinarianDetails'],
      ),
      patientHints: _strings(json['patientHints']),
      diagnoses: items(json['diagnoses']),
      medications: items(json['medications']),
      vaccinations: items(json['vaccinations']),
      medicalOrders: items(json['medicalOrders']),
      clinicalHistory: _nullableMap(json['clinicalHistory']),
      diagnosticResults: items(json['diagnosticResults']),
      referral: _nullableMap(json['referral']),
      additionalFields: additionalFields,
      warnings: _strings(json['warnings']),
    );
  }

  static MedicalDocumentItemEntity _itemFromJson(Map<String, dynamic> json) {
    final fields = Map<String, dynamic>.from(json)
      ..remove('id')
      ..remove('confidence')
      ..remove('source');
    final sourceJson = _nullableMap(json['source']);
    return MedicalDocumentItemEntity(
      id: json['id']?.toString() ?? '',
      confidence: _double(json['confidence']),
      source: sourceJson == null
          ? null
          : MedicalDocumentSourceEntity(
              page: _nullableInteger(sourceJson['page']),
              text: sourceJson['text']?.toString(),
            ),
      fields: fields,
    );
  }

  static Map<String, dynamic> extractionToJson(
    MedicalDocumentExtractionEntity extraction,
  ) {
    Map<String, dynamic> itemToJson(MedicalDocumentItemEntity item) {
      return <String, dynamic>{
        'id': item.id,
        ...item.fields,
        if (item.confidence != null) 'confidence': item.confidence,
        if (item.source != null)
          'source': {
            if (item.source!.page != null) 'page': item.source!.page,
            if (item.source!.text != null) 'text': item.source!.text,
          },
      };
    }

    return <String, dynamic>{
      'documentType': extraction.documentType.wireValue,
      if (extraction.documentTypeConfidence != null)
        'documentTypeConfidence': extraction.documentTypeConfidence,
      if (extraction.summary != null) 'summary': extraction.summary,
      if (extraction.documentDate != null)
        'documentDate': extraction.documentDate,
      if (extraction.issuer != null) 'issuer': extraction.issuer,
      'patientHints': extraction.patientHints,
      'diagnoses': extraction.diagnoses.map(itemToJson).toList(),
      'medications': extraction.medications.map(itemToJson).toList(),
      'vaccinations': extraction.vaccinations.map(itemToJson).toList(),
      'medicalOrders': extraction.medicalOrders.map(itemToJson).toList(),
      if (extraction.clinicalHistory != null)
        'clinicalHistory': extraction.clinicalHistory,
      if (extraction.diagnosticResults.isNotEmpty)
        'diagnosticResults': extraction.diagnosticResults
            .map(itemToJson)
            .toList(),
      if (extraction.referral != null) 'referral': extraction.referral,
      'additionalFields': extraction.additionalFields,
      'warnings': extraction.warnings,
    };
  }

  static Map<String, dynamic> reviewRequestToJson(
    ReviewMedicalDocumentRequest request,
  ) {
    if (request.decision == MedicalDocumentReviewDecision.reject) {
      return {'decision': 'REJECT', 'documentVersion': request.documentVersion};
    }
    return {
      'decision': 'ACCEPT',
      'documentVersion': request.documentVersion,
      'finalCategory': request.finalCategory!.wireValue,
      'validatedExtraction': extractionToJson(request.validatedExtraction!),
      'assignments': request.assignments
          .map(
            (assignment) => {
              'animalId': assignment.animalId,
              'extractedItemIds': assignment.extractedItemIds,
            },
          )
          .toList(),
    };
  }
}

List<MedicalDocumentAnimalEntity> _animalDetails(Map<String, dynamic> json) {
  final values = <Map<String, dynamic>>[
    for (final candidate in [
      json['animalDetails'],
      json['animalsData'],
      json['animals'],
      json['patients'],
      json['animal'],
      json['patient'],
      json['patientData'],
      json['animalData'],
      json['animalInfo'],
    ])
      ..._patientMaps(candidate),
  ];
  final extractionValues = <Object?>[
    ..._map(json['extractionsByCategory']).values,
    json['validatedExtraction'],
  ];
  for (final rawExtraction in extractionValues) {
    final extraction = _nullableMap(rawExtraction);
    if (extraction == null) continue;
    for (final candidate in [
      extraction['patient'],
      extraction['patientDetails'],
      extraction['patientHints'],
      extraction['animal'],
      extraction['animalDetails'],
    ]) {
      values.addAll(_patientMaps(candidate));
    }
    final additional = _nullableMap(extraction['additionalFields']);
    if (additional != null) {
      for (final candidate in [
        additional['patient'],
        additional['patientDetails'],
        additional['patientHints'],
        additional['animal'],
        additional['animalDetails'],
      ]) {
        values.addAll(_patientMaps(candidate));
      }
      if (additional.entries.any(
        (entry) =>
            entry.value is! Map &&
            entry.value is! Iterable &&
            _isPatientFieldKey(entry.key),
      )) {
        values.add(additional);
      }
    }
  }
  final seen = <String>{};
  return values
      .map((animal) {
        return MedicalDocumentAnimalEntity(
          id: _firstText(animal, const ['id', 'animalId', 'patientId']),
          name: _firstText(animal, const [
            'name',
            'animalName',
            'patientName',
            'fullName',
          ]),
          code: _nullableText(animal, const [
            'code',
            'recordId',
            'animalRecordId',
            'animalRecordCode',
          ]),
          species: _nullableText(animal, const ['species', 'family']),
          breed: _nullableText(animal, const ['breed', 'race']),
          sex: _nullableText(animal, const ['sex', 'gender', 'patientSex']),
          color: _nullableText(animal, const [
            'color',
            'coatColor',
            'patientColor',
          ]),
          birthdate: _nullableText(animal, const [
            'birthdate',
            'birthDate',
            'dateOfBirth',
          ]),
          age: _nullableText(animal, const ['age']),
          weight: _nullableText(animal, const ['weight']),
          fields: _patientFields(animal),
          additionalDetails: _additionalTextFields(
            animal,
            excludedKeys: _knownAnimalKeys,
          ),
        );
      })
      .where((animal) {
        if (animal.id.isEmpty &&
            animal.name.isEmpty &&
            (animal.code?.isEmpty ?? true) &&
            (animal.species?.isEmpty ?? true) &&
            (animal.breed?.isEmpty ?? true) &&
            (animal.sex?.isEmpty ?? true) &&
            (animal.color?.isEmpty ?? true) &&
            (animal.birthdate?.isEmpty ?? true) &&
            (animal.age?.isEmpty ?? true) &&
            (animal.weight?.isEmpty ?? true) &&
            animal.fields.isEmpty &&
            animal.additionalDetails.isEmpty) {
          return false;
        }
        final key = [
          animal.id,
          animal.name,
          animal.code,
          animal.species,
          animal.breed,
          animal.sex,
          animal.color,
          animal.age,
          animal.weight,
          animal.fields,
          animal.additionalDetails,
        ].join('|');
        return seen.add(key);
      })
      .toList(growable: false);
}

MedicalDocumentTutorEntity? _tutorDetails(Map<String, dynamic> json) {
  final fields = _tutorFields(json);
  final candidates = <Object?>[];
  _collectTutorCandidates(candidates, json);
  final values = candidates
      .map(_nullableMap)
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
  final name = _firstTextAcross(values, const [
    'name',
    'fullName',
    'ownerName',
    'nombre',
    'nombreCompleto',
    'full_name',
    'owner_name',
    'tutor_name',
  ]);
  final identification = _firstTextAcross(values, const [
    'identification',
    'identificationNumber',
    'documentNumber',
    'document',
    'idNumber',
    'documentId',
    'document_number',
    'identification_number',
    'id_number',
    'identificacion',
    'identificación',
    'numeroDocumento',
    'númeroDocumento',
    'documento',
    'cedula',
    'cédula',
    'dni',
  ]);
  final phoneNumber = _firstTextAcross(values, const [
    'phoneNumber',
    'cellPhone',
    'mobileNumber',
    'mobile',
    'phone',
    'telephone',
    'telefono',
    'teléfono',
    'celular',
    'mobile_phone',
    'phone_number',
    'mobile_number',
  ]);
  final additionalDetails = <String, String>{};
  for (final value in values) {
    for (final entry in _additionalTextFields(
      value,
      excludedKeys: _knownTutorKeys,
    ).entries) {
      additionalDetails.putIfAbsent(entry.key, () => entry.value);
    }
  }
  if (name.isEmpty &&
      identification.isEmpty &&
      phoneNumber.isEmpty &&
      fields.isEmpty &&
      additionalDetails.isEmpty) {
    return null;
  }
  return MedicalDocumentTutorEntity(
    name: name,
    identification: identification,
    phoneNumber: phoneNumber,
    fields: fields,
    additionalDetails: additionalDetails,
  );
}

Map<String, String> _tutorFields(Map<String, dynamic> json) {
  final result = <String, String>{};

  void collect(Object? value, {bool tutorContext = false, int depth = 0}) {
    if (value == null || depth > 12) return;
    if (value is List) {
      if (tutorContext) {
        for (final entry in _labeledValues(value).entries) {
          result.putIfAbsent(entry.key, () => entry.value.toString());
        }
      }
      for (final item in value) {
        collect(item, tutorContext: tutorContext, depth: depth + 1);
      }
      return;
    }
    final map = _nullableMap(value);
    if (map == null) return;

    if (tutorContext) {
      final label = _nullableText(map, const [
        'label',
        'field',
        'key',
        'title',
        'concept',
        'campo',
        'etiqueta',
      ]);
      final labeledValue = _nullableText(map, const [
        'value',
        'text',
        'content',
        'data',
        'valor',
      ]);
      if (label != null && labeledValue != null) {
        result.putIfAbsent(label, () => labeledValue);
      } else {
        for (final entry in map.entries) {
          if (entry.value is Map || entry.value is Iterable) continue;
          if (const {'source', 'confidence'}.contains(entry.key)) continue;
          final text = _valueText(entry.value);
          if (text?.isNotEmpty == true) {
            result.putIfAbsent(entry.key, () => text!);
          }
        }
      }
    }

    for (final entry in map.entries) {
      final isTutorField = _isTutorContainerKey(entry.key);
      if (!tutorContext &&
          isTutorField &&
          entry.value is! Map &&
          entry.value is! Iterable) {
        final text = _valueText(entry.value);
        if (text?.isNotEmpty == true) {
          result.putIfAbsent(entry.key, () => text!);
        }
      }
      collect(
        entry.value,
        tutorContext: tutorContext || isTutorField,
        depth: depth + 1,
      );
    }
  }

  collect(json);
  return result;
}

void _collectTutorCandidates(
  List<Object?> candidates,
  Object? value, {
  String? parentKey,
  int depth = 0,
}) {
  if (depth > 12 || value == null) return;
  final map = _nullableMap(value);
  if (map != null) {
    final hasTutorContext =
        (parentKey != null && _isTutorContainerKey(parentKey)) ||
        _hasTutorMarker(map);
    if (hasTutorContext) {
      candidates.add(map);
      candidates.add(_structuredTutorDetails(map));
    }
    _addTutorCandidates(candidates, map);
    for (final entry in map.entries) {
      final nestedMap = _nullableMap(entry.value);
      if (nestedMap != null && _isTutorContainerKey(entry.key)) {
        candidates.add(nestedMap);
      } else if (entry.value is List && _isTutorContainerKey(entry.key)) {
        candidates.add(_tutorHintsDetails(entry.value));
      }
      _collectTutorCandidates(
        candidates,
        entry.value,
        parentKey: entry.key,
        depth: depth + 1,
      );
    }
    return;
  }
  if (value is Iterable) {
    for (final item in value) {
      _collectTutorCandidates(
        candidates,
        item,
        parentKey: parentKey,
        depth: depth + 1,
      );
    }
  }
}

bool _isTutorContainerKey(String key) {
  final normalized = _normalizedKey(key);
  if (normalized == 'ownerid' ||
      normalized == 'tutorid' ||
      normalized == 'guardianid' ||
      normalized == 'propietarioid') {
    return false;
  }
  return _partyKeyTokens.any(normalized.contains);
}

bool _hasTutorMarker(Map<String, dynamic> values) {
  for (final entry in values.entries) {
    if (entry.value is Map || entry.value is Iterable) continue;
    if (_isTutorContainerKey(entry.key)) return true;
    final normalizedKey = _normalizedKey(entry.key);
    if (_labelKeys.contains(normalizedKey)) {
      final label = _valueText(entry.value);
      if (label != null && _isTutorContainerKey(label)) return true;
    }
  }
  return false;
}

Map<String, dynamic>? _structuredTutorDetails(Map<String, dynamic> values) {
  final result = <String, dynamic>{};
  final label = _nullableText(values, const [
    'label',
    'field',
    'key',
    'title',
    'concept',
    'campo',
    'etiqueta',
  ]);
  final labeledValue = _nullableText(values, const [
    'value',
    'text',
    'content',
    'data',
    'valor',
  ]);
  if (label != null && labeledValue != null) {
    final field = _tutorFieldForLabel(label);
    if (field != null) result[field] = labeledValue;
  }

  for (final entry in values.entries) {
    if (entry.value is Map || entry.value is Iterable) continue;
    final field = _tutorFieldForLabel(entry.key);
    final value = _valueText(entry.value);
    if (field != null && value != null && value.isNotEmpty) {
      result.putIfAbsent(field, () => value);
    }
  }
  return result.isEmpty ? null : result;
}

String? _tutorFieldForLabel(String label) {
  final normalized = _normalizedKey(label);
  if (_containsAny(normalized, const ['email', 'correo'])) return 'email';
  if (_containsAny(normalized, const ['address', 'direccion', 'domicilio'])) {
    return 'address';
  }
  if (_containsAny(normalized, const [
    'phone',
    'telefono',
    'mobile',
    'celular',
    'telephone',
  ])) {
    return 'phoneNumber';
  }
  if (_containsAny(normalized, const [
    'identification',
    'identificacion',
    'document',
    'documento',
    'cedula',
    'dni',
  ])) {
    return 'identification';
  }
  if (const {
        'name',
        'fullname',
        'nombre',
        'nombrecompleto',
      }.contains(normalized) ||
      (_partyKeyTokens.any(normalized.contains) &&
          _containsAny(normalized, const ['name', 'nombre']))) {
    return 'name';
  }
  return null;
}

bool _containsAny(String value, List<String> tokens) {
  return tokens.any(value.contains);
}

const _labelKeys = {
  'label',
  'field',
  'key',
  'title',
  'concept',
  'campo',
  'etiqueta',
};

void _addTutorCandidates(
  List<Object?> candidates,
  Map<String, dynamic>? values,
) {
  if (values == null) return;
  const nestedKeys = [
    'tutor',
    'tutorDetails',
    'tutorData',
    'owner',
    'ownerDetails',
    'ownerData',
    'ownerInfo',
    'petOwner',
    'guardian',
    'guardianDetails',
    'responsible',
    'responsiblePerson',
    'caregiver',
    'client',
    'customer',
    'proprietor',
    'proprietorDetails',
    'propietario',
    'datosPropietario',
    'responsable',
  ];
  for (final key in nestedKeys) {
    final value = values[key];
    if (value is String && value.trim().isNotEmpty) {
      candidates.add({'name': value.trim()});
    } else if (value is List) {
      candidates.add(_tutorHintsDetails(value));
    } else {
      candidates.add(value);
    }
  }
  for (final key in const [
    'tutorHints',
    'ownerHints',
    'guardianHints',
    'proprietorHints',
    'propietarioHints',
  ]) {
    final value = values[key];
    candidates.add(value is Map ? value : _tutorHintsDetails(value));
  }
  candidates.add(_flatTutorDetails(values));
}

Map<String, dynamic>? _tutorHintsDetails(Object? value) {
  final values = _labeledValues(value);
  return values.isEmpty ? null : values;
}

Map<String, dynamic>? _flatTutorDetails(Map<String, dynamic>? values) {
  if (values == null) return null;
  final result = <String, dynamic>{
    'name': _inferredTutorValue(values, const ['name', 'nombre']),
    'identification': _inferredTutorValue(values, const [
      'identification',
      'identificacion',
      'document',
      'documento',
      'cedula',
      'dni',
      'idnumber',
    ]),
    'phoneNumber': _inferredTutorValue(values, const [
      'phone',
      'telefono',
      'mobile',
      'celular',
      'telephone',
    ]),
    'email': _inferredTutorValue(values, const ['email', 'correo']),
    'address': _inferredTutorValue(values, const ['address', 'direccion']),
  }..removeWhere((_, value) => value == null);
  return result.isEmpty ? null : result;
}

String? _inferredTutorValue(
  Map<String, dynamic> values,
  List<String> fieldTokens,
) {
  for (final entry in values.entries) {
    final key = _normalizedKey(entry.key);
    if (!_partyKeyTokens.any(key.contains) || !fieldTokens.any(key.contains)) {
      continue;
    }
    final value = _valueText(entry.value);
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

const _partyKeyTokens = [
  'owner',
  'tutor',
  'guardian',
  'proprietor',
  'propietario',
  'responsable',
  'responsible',
  'caregiver',
  'client',
  'customer',
  'tenedor',
  'acudiente',
];

String _normalizedKey(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9áéíóúñ]'), '')
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ñ', 'n');
}

const _flatPatientKeys = {
  'patientId',
  'patientName',
  'recordId',
  'code',
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
};

const _knownAnimalKeys = {
  'id',
  'animalId',
  'patientId',
  'name',
  'animalName',
  'patientName',
  'fullName',
  'code',
  'recordId',
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
  'tutorData',
  'owner',
  'ownerDetails',
  'ownerData',
  'ownerInfo',
  'petOwner',
  'guardian',
  'guardianDetails',
  'responsible',
  'responsiblePerson',
  'caregiver',
  'client',
  'customer',
  'proprietor',
  'proprietorDetails',
  'propietario',
  'datosPropietario',
  'responsable',
  'tutorHints',
  'ownerHints',
  'guardianHints',
  'proprietorHints',
  'propietarioHints',
  'source',
  'confidence',
};

const _knownTutorKeys = {
  'id',
  'name',
  'fullName',
  'ownerName',
  'nombre',
  'nombreCompleto',
  'full_name',
  'owner_name',
  'tutor_name',
  'identification',
  'identificationNumber',
  'documentNumber',
  'document',
  'idNumber',
  'documentId',
  'document_number',
  'identification_number',
  'id_number',
  'identificacion',
  'identificación',
  'numeroDocumento',
  'númeroDocumento',
  'documento',
  'cedula',
  'cédula',
  'dni',
  'phoneNumber',
  'cellPhone',
  'mobileNumber',
  'mobile',
  'phone',
  'telephone',
  'telefono',
  'teléfono',
  'celular',
  'mobile_phone',
  'phone_number',
  'mobile_number',
  'label',
  'field',
  'key',
  'title',
  'concept',
  'campo',
  'etiqueta',
  'value',
  'text',
  'content',
  'data',
  'valor',
  'source',
  'confidence',
};

Iterable<Map<String, dynamic>> _objectMaps(Object? value) sync* {
  if (value is List) {
    for (final item in value) {
      final map = _nullableMap(item);
      if (map != null) yield map;
    }
    return;
  }
  final map = _nullableMap(value);
  if (map == null) return;
  const directKeys = {
    'id',
    'animalId',
    'patientId',
    'name',
    'animalName',
    'patientName',
    'code',
    'recordId',
    'animalRecordId',
    'species',
    'breed',
    'race',
    'sex',
    'gender',
    'color',
    'age',
    'weight',
  };
  if (map.keys.any(directKeys.contains)) {
    yield map;
    return;
  }
  for (final entry in map.entries) {
    final nested = _nullableMap(entry.value);
    if (nested == null) continue;
    yield {
      if (!nested.containsKey('id') && !nested.containsKey('animalId'))
        'id': entry.key,
      ...nested,
    };
  }
}

Iterable<Map<String, dynamic>> _patientMaps(Object? value) sync* {
  yield* _objectMaps(value);
  final labeledValues = _labeledValues(value);
  if (labeledValues.isNotEmpty) yield labeledValues;
}

Map<String, dynamic> _labeledValues(Object? value) {
  if (value is! List) return const {};
  final fields = <String, dynamic>{};
  for (final item in value.whereType<String>()) {
    final separator = item.indexOf(':');
    if (separator <= 0) continue;
    final label = item.substring(0, separator).trim();
    final fieldValue = item.substring(separator + 1).trim();
    if (label.isEmpty || fieldValue.isEmpty) continue;
    fields[label] = fieldValue;
  }
  return fields;
}

bool _isPatientFieldKey(String key) {
  final normalized = _normalizedKey(key);
  return _flatPatientKeys.any(
        (candidate) => _normalizedKey(candidate) == normalized,
      ) ||
      normalized.contains('animal') ||
      normalized.contains('patient');
}

Map<String, String> _patientFields(Map<String, dynamic> values) {
  return {
    for (final entry in values.entries)
      if (entry.key != 'source' &&
          entry.key != 'confidence' &&
          !_isTutorContainerKey(entry.key) &&
          _valueText(entry.value)?.isNotEmpty == true)
        entry.key: _valueText(entry.value)!,
  };
}

String _firstText(Map<String, dynamic> values, List<String> keys) {
  return _nullableText(values, keys) ?? '';
}

String _firstTextAcross(List<Map<String, dynamic>> values, List<String> keys) {
  for (final value in values) {
    final text = _nullableText(value, keys);
    if (text != null && text.isNotEmpty) return text;
  }
  return '';
}

String? _nullableText(Map<String, dynamic> values, List<String> keys) {
  for (final key in keys) {
    final text = _valueText(values[key]);
    if (text != null && text.isNotEmpty) return text;
  }
  final normalizedKeys = keys.map(_normalizedKey).toSet();
  for (final entry in values.entries) {
    if (!normalizedKeys.contains(_normalizedKey(entry.key))) continue;
    final text = _valueText(entry.value);
    if (text != null && text.isNotEmpty) return text;
  }
  return null;
}

String? _valueText(Object? value) {
  if (value == null) return null;
  if (value is String) return value.trim();
  if (value is num || value is bool) return value.toString();
  if (value is Iterable) {
    final items = value
        .map(_valueText)
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return items.isEmpty ? null : items.join(', ');
  }
  final map = _nullableMap(value);
  if (map == null) return null;
  final rawValue = _nullableText(map, const [
    'name',
    'label',
    'value',
    'text',
    'code',
  ]);
  final unit = _nullableText(map, const ['unit', 'units']);
  if (rawValue == null) return null;
  return unit == null ? rawValue : '$rawValue $unit';
}

Map<String, String> _additionalTextFields(
  Map<String, dynamic> values, {
  required Set<String> excludedKeys,
}) {
  return {
    for (final entry in values.entries)
      if (!excludedKeys.contains(entry.key) &&
          _valueText(entry.value)?.isNotEmpty == true)
        entry.key: _valueText(entry.value)!,
  };
}

List<dynamic> _list(Object? value) => value is List ? value : const [];

Map<String, dynamic> _map(Object? value) =>
    _nullableMap(value) ?? <String, dynamic>{};

Map<String, dynamic>? _nullableMap(Object? value) {
  if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return null;
}

List<String> _strings(Object? value) =>
    _list(value).map((item) => item.toString()).toList(growable: false);

int _integer(Object? value, {int fallback = 0}) =>
    _nullableInteger(value) ?? fallback;

int? _nullableInteger(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

double? _double(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');

DateTime? _date(Object? value) => DateTime.tryParse(value?.toString() ?? '');
