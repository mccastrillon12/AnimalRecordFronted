import 'package:equatable/equatable.dart';

const _unchangedMedicalField = Object();

enum MedicalDocumentCategory {
  prescription('PRESCRIPTION', 'Formula'),
  medicalOrder('MEDICAL_ORDER', 'Orden medica'),
  referral('REFERRAL', 'Remisión'),
  vaccinationCard('VACCINATION_CARD', 'Carnet de vacunación'),
  clinicalHistory('CLINICAL_HISTORY', 'Historia clinica'),
  diagnosticImage('DIAGNOSTIC_IMAGE', 'Imagen Diagnostica'),
  laboratoryResult('LABORATORY_RESULT', 'Resultados de laboratorio'),
  other('OTHER', 'Archivo no identificado');

  final String wireValue;
  final String label;

  const MedicalDocumentCategory(this.wireValue, this.label);

  static MedicalDocumentCategory? tryParse(Object? value) {
    final normalized = value?.toString().toUpperCase();
    for (final category in values) {
      if (category.wireValue == normalized) return category;
    }
    return null;
  }
}

enum MedicalDocumentStatus {
  pendingUpload('PENDING_UPLOAD'),
  analyzing('ANALYZING'),
  reviewPending('REVIEW_PENDING'),
  accepted('ACCEPTED'),
  rejected('REJECTED'),
  failed('FAILED');

  final String wireValue;

  const MedicalDocumentStatus(this.wireValue);

  static MedicalDocumentStatus parse(Object? value) {
    final normalized = value?.toString().toUpperCase();
    return values.firstWhere(
      (status) => status.wireValue == normalized,
      orElse: () => MedicalDocumentStatus.failed,
    );
  }
}

enum MedicalDocumentClassificationOutcome {
  match('MATCH'),
  mismatch('MISMATCH'),
  matchWithAdditional('MATCH_WITH_ADDITIONAL'),
  multiple('MULTIPLE'),
  detected('DETECTED'),
  unclassified('UNCLASSIFIED');

  final String wireValue;

  const MedicalDocumentClassificationOutcome(this.wireValue);

  static MedicalDocumentClassificationOutcome? tryParse(Object? value) {
    final normalized = value?.toString().toUpperCase();
    for (final outcome in values) {
      if (outcome.wireValue == normalized) return outcome;
    }
    return null;
  }
}

class DetectedMedicalDocumentCategoryEntity extends Equatable {
  final MedicalDocumentCategory category;
  final double? confidence;
  final int? pageStart;
  final int? pageEnd;
  final String? summary;
  final String? evidence;

  const DetectedMedicalDocumentCategoryEntity({
    required this.category,
    this.confidence,
    this.pageStart,
    this.pageEnd,
    this.summary,
    this.evidence,
  });

  @override
  List<Object?> get props => [
    category,
    confidence,
    pageStart,
    pageEnd,
    summary,
    evidence,
  ];
}

class MedicalDocumentSourceEntity extends Equatable {
  final int? page;
  final String? text;

  const MedicalDocumentSourceEntity({this.page, this.text});

  @override
  List<Object?> get props => [page, text];
}

class MedicalDocumentItemEntity extends Equatable {
  final String id;
  final double? confidence;
  final MedicalDocumentSourceEntity? source;
  final Map<String, dynamic> fields;

  const MedicalDocumentItemEntity({
    required this.id,
    this.confidence,
    this.source,
    this.fields = const {},
  });

  String get name => fields['name']?.toString() ?? '';

  MedicalDocumentItemEntity copyWith({Map<String, dynamic>? fields}) {
    return MedicalDocumentItemEntity(
      id: id,
      confidence: confidence,
      source: source,
      fields: fields ?? this.fields,
    );
  }

  @override
  List<Object?> get props => [id, confidence, source, fields];
}

class MedicalDocumentPatientEntity extends Equatable {
  final String? name;
  final String? identifier;
  final String? species;
  final String? breed;
  final String? sex;
  final String? color;
  final String? size;
  final String? reproductiveStatus;
  final String? age;
  final String? birthDate;
  final String? weight;
  final String? microchip;
  final Map<String, String> fields;

  const MedicalDocumentPatientEntity({
    this.name,
    this.identifier,
    this.species,
    this.breed,
    this.sex,
    this.color,
    this.size,
    this.reproductiveStatus,
    this.age,
    this.birthDate,
    this.weight,
    this.microchip,
    this.fields = const {},
  });

  bool get hasData =>
      [
        name,
        identifier,
        species,
        breed,
        sex,
        color,
        size,
        reproductiveStatus,
        age,
        birthDate,
        weight,
        microchip,
      ].any((value) => value?.trim().isNotEmpty == true) ||
      fields.entries.any(
        (entry) => entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty,
      );

  MedicalDocumentPatientEntity copyWith({
    Object? name = _unchangedMedicalField,
    Object? identifier = _unchangedMedicalField,
    Object? species = _unchangedMedicalField,
    Object? breed = _unchangedMedicalField,
    Object? sex = _unchangedMedicalField,
    Object? color = _unchangedMedicalField,
    Object? size = _unchangedMedicalField,
    Object? reproductiveStatus = _unchangedMedicalField,
    Object? age = _unchangedMedicalField,
    Object? birthDate = _unchangedMedicalField,
    Object? weight = _unchangedMedicalField,
    Object? microchip = _unchangedMedicalField,
    Map<String, String>? fields,
  }) {
    return MedicalDocumentPatientEntity(
      name: identical(name, _unchangedMedicalField)
          ? this.name
          : name as String?,
      identifier: identical(identifier, _unchangedMedicalField)
          ? this.identifier
          : identifier as String?,
      species: identical(species, _unchangedMedicalField)
          ? this.species
          : species as String?,
      breed: identical(breed, _unchangedMedicalField)
          ? this.breed
          : breed as String?,
      sex: identical(sex, _unchangedMedicalField) ? this.sex : sex as String?,
      color: identical(color, _unchangedMedicalField)
          ? this.color
          : color as String?,
      size: identical(size, _unchangedMedicalField)
          ? this.size
          : size as String?,
      reproductiveStatus: identical(reproductiveStatus, _unchangedMedicalField)
          ? this.reproductiveStatus
          : reproductiveStatus as String?,
      age: identical(age, _unchangedMedicalField) ? this.age : age as String?,
      birthDate: identical(birthDate, _unchangedMedicalField)
          ? this.birthDate
          : birthDate as String?,
      weight: identical(weight, _unchangedMedicalField)
          ? this.weight
          : weight as String?,
      microchip: identical(microchip, _unchangedMedicalField)
          ? this.microchip
          : microchip as String?,
      fields: fields ?? this.fields,
    );
  }

  @override
  List<Object?> get props => [
    name,
    identifier,
    species,
    breed,
    sex,
    color,
    size,
    reproductiveStatus,
    age,
    birthDate,
    weight,
    microchip,
    fields,
  ];
}

class MedicalDocumentOwnerEntity extends Equatable {
  final String? name;
  final String? identification;
  final String? phone;
  final String? email;
  final String? address;

  const MedicalDocumentOwnerEntity({
    this.name,
    this.identification,
    this.phone,
    this.email,
    this.address,
  });

  bool get hasData =>
      props.any((value) => value?.toString().trim().isNotEmpty == true);

  MedicalDocumentOwnerEntity copyWith({
    Object? name = _unchangedMedicalField,
    Object? identification = _unchangedMedicalField,
    Object? phone = _unchangedMedicalField,
    Object? email = _unchangedMedicalField,
    Object? address = _unchangedMedicalField,
  }) {
    return MedicalDocumentOwnerEntity(
      name: identical(name, _unchangedMedicalField)
          ? this.name
          : name as String?,
      identification: identical(identification, _unchangedMedicalField)
          ? this.identification
          : identification as String?,
      phone: identical(phone, _unchangedMedicalField)
          ? this.phone
          : phone as String?,
      email: identical(email, _unchangedMedicalField)
          ? this.email
          : email as String?,
      address: identical(address, _unchangedMedicalField)
          ? this.address
          : address as String?,
    );
  }

  @override
  List<Object?> get props => [name, identification, phone, email, address];
}

class MedicalDocumentExtractionEntity extends Equatable {
  final MedicalDocumentCategory documentType;
  final double? documentTypeConfidence;
  final String? summary;
  final String? documentDate;
  final Map<String, dynamic>? issuer;
  final MedicalDocumentPatientEntity? patient;
  final MedicalDocumentOwnerEntity? owner;
  final List<String> patientHints;
  final List<MedicalDocumentItemEntity> diagnoses;
  final List<MedicalDocumentItemEntity> medications;
  final List<MedicalDocumentItemEntity> vaccinations;
  final List<MedicalDocumentItemEntity> medicalOrders;
  final Map<String, dynamic>? clinicalHistory;
  final List<MedicalDocumentItemEntity> diagnosticResults;
  final Map<String, dynamic>? referral;
  final List<MedicalDocumentItemEntity> diagnosticImages;
  final Map<String, dynamic>? laboratoryReport;
  final List<MedicalDocumentItemEntity> laboratoryResults;
  final Map<String, dynamic> additionalFields;

  /// Lossless extraction received from the backend. It is used only when the
  /// user archives the file under a category different from [documentType].
  final Map<String, dynamic> rawExtraction;

  /// Canonical properties returned by the backend that this app version does
  /// not model yet. They are deliberately not rendered, but must survive a
  /// review round-trip.
  final Map<String, dynamic> preservedUnknownFields;
  final List<String> warnings;

  const MedicalDocumentExtractionEntity({
    required this.documentType,
    this.documentTypeConfidence,
    this.summary,
    this.documentDate,
    this.issuer,
    this.patient,
    this.owner,
    this.patientHints = const [],
    this.diagnoses = const [],
    this.medications = const [],
    this.vaccinations = const [],
    this.medicalOrders = const [],
    this.clinicalHistory,
    this.diagnosticResults = const [],
    this.referral,
    this.diagnosticImages = const [],
    this.laboratoryReport,
    this.laboratoryResults = const [],
    this.additionalFields = const {},
    this.rawExtraction = const {},
    this.preservedUnknownFields = const {},
    this.warnings = const [],
  });

  factory MedicalDocumentExtractionEntity.empty(
    MedicalDocumentCategory category,
  ) => MedicalDocumentExtractionEntity(documentType: category);

  List<String> get extractedItemIds => [
    ...diagnoses.map((item) => item.id),
    ...medications.map((item) => item.id),
    ...vaccinations.map((item) => item.id),
    ...medicalOrders.map((item) => item.id),
    ...diagnosticResults.map((item) => item.id),
    ...diagnosticImages.map((item) => item.id),
    ...laboratoryResults.map((item) => item.id),
  ];

  MedicalDocumentExtractionEntity copyWith({
    MedicalDocumentCategory? documentType,
    double? documentTypeConfidence,
    String? summary,
    String? documentDate,
    Map<String, dynamic>? issuer,
    MedicalDocumentPatientEntity? patient,
    MedicalDocumentOwnerEntity? owner,
    List<String>? patientHints,
    List<MedicalDocumentItemEntity>? diagnoses,
    List<MedicalDocumentItemEntity>? medications,
    List<MedicalDocumentItemEntity>? vaccinations,
    List<MedicalDocumentItemEntity>? medicalOrders,
    Map<String, dynamic>? clinicalHistory,
    List<MedicalDocumentItemEntity>? diagnosticResults,
    Map<String, dynamic>? referral,
    List<MedicalDocumentItemEntity>? diagnosticImages,
    Map<String, dynamic>? laboratoryReport,
    List<MedicalDocumentItemEntity>? laboratoryResults,
    Map<String, dynamic>? additionalFields,
    Map<String, dynamic>? rawExtraction,
    Map<String, dynamic>? preservedUnknownFields,
    List<String>? warnings,
  }) {
    return MedicalDocumentExtractionEntity(
      documentType: documentType ?? this.documentType,
      documentTypeConfidence:
          documentTypeConfidence ?? this.documentTypeConfidence,
      summary: summary ?? this.summary,
      documentDate: documentDate ?? this.documentDate,
      issuer: issuer ?? this.issuer,
      patient: patient ?? this.patient,
      owner: owner ?? this.owner,
      patientHints: patientHints ?? this.patientHints,
      diagnoses: diagnoses ?? this.diagnoses,
      medications: medications ?? this.medications,
      vaccinations: vaccinations ?? this.vaccinations,
      medicalOrders: medicalOrders ?? this.medicalOrders,
      clinicalHistory: clinicalHistory ?? this.clinicalHistory,
      diagnosticResults: diagnosticResults ?? this.diagnosticResults,
      referral: referral ?? this.referral,
      diagnosticImages: diagnosticImages ?? this.diagnosticImages,
      laboratoryReport: laboratoryReport ?? this.laboratoryReport,
      laboratoryResults: laboratoryResults ?? this.laboratoryResults,
      additionalFields: additionalFields ?? this.additionalFields,
      rawExtraction: rawExtraction ?? this.rawExtraction,
      preservedUnknownFields:
          preservedUnknownFields ?? this.preservedUnknownFields,
      warnings: warnings ?? this.warnings,
    );
  }

  MedicalDocumentExtractionEntity sanitizedFor(
    MedicalDocumentCategory category,
  ) {
    return MedicalDocumentExtractionEntity(
      documentType: category,
      documentTypeConfidence: documentTypeConfidence,
      summary: summary,
      documentDate: documentDate,
      issuer: issuer == null ? null : _deepCopyMap(issuer!),
      patient: patient,
      owner: owner,
      patientHints: List.unmodifiable(patientHints),
      diagnoses: switch (category) {
        MedicalDocumentCategory.prescription ||
        MedicalDocumentCategory.medicalOrder ||
        MedicalDocumentCategory.referral ||
        MedicalDocumentCategory.clinicalHistory => _copyItems(diagnoses),
        _ => const [],
      },
      medications: switch (category) {
        MedicalDocumentCategory.prescription ||
        MedicalDocumentCategory.referral => _copyItems(medications),
        _ => const [],
      },
      vaccinations: category == MedicalDocumentCategory.vaccinationCard
          ? _copyItems(vaccinations)
          : const [],
      medicalOrders: category == MedicalDocumentCategory.medicalOrder
          ? _copyItems(medicalOrders)
          : const [],
      clinicalHistory: category == MedicalDocumentCategory.clinicalHistory
          ? clinicalHistory == null
                ? null
                : _deepCopyMap(clinicalHistory!)
          : null,
      diagnosticResults:
          category == MedicalDocumentCategory.referral ||
              category == MedicalDocumentCategory.clinicalHistory
          ? _copyItems(diagnosticResults)
          : const [],
      referral: category == MedicalDocumentCategory.referral && referral != null
          ? _deepCopyMap(referral!)
          : null,
      diagnosticImages: category == MedicalDocumentCategory.diagnosticImage
          ? _copyItems(diagnosticImages)
          : const [],
      laboratoryReport:
          category == MedicalDocumentCategory.laboratoryResult &&
              laboratoryReport != null
          ? _deepCopyMap(laboratoryReport!)
          : null,
      laboratoryResults: category == MedicalDocumentCategory.laboratoryResult
          ? _copyItems(laboratoryResults)
          : const [],
      additionalFields: _deepCopyMap(additionalFields),
      rawExtraction: _deepCopyMap(rawExtraction),
      preservedUnknownFields: _deepCopyMap(preservedUnknownFields),
      warnings: List.unmodifiable(warnings),
    );
  }

  @override
  List<Object?> get props => [
    documentType,
    documentTypeConfidence,
    summary,
    documentDate,
    issuer,
    patient,
    owner,
    patientHints,
    diagnoses,
    medications,
    vaccinations,
    medicalOrders,
    clinicalHistory,
    diagnosticResults,
    referral,
    diagnosticImages,
    laboratoryReport,
    laboratoryResults,
    additionalFields,
    rawExtraction,
    preservedUnknownFields,
    warnings,
  ];
}

List<MedicalDocumentItemEntity> _copyItems(
  List<MedicalDocumentItemEntity> items,
) => List.unmodifiable(
  items.map(
    (item) => MedicalDocumentItemEntity(
      id: item.id,
      confidence: item.confidence,
      source: item.source,
      fields: _deepCopyMap(item.fields),
    ),
  ),
);

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

class MedicalDocumentAssignmentEntity extends Equatable {
  final String animalId;
  final List<String> extractedItemIds;

  const MedicalDocumentAssignmentEntity({
    required this.animalId,
    this.extractedItemIds = const [],
  });

  @override
  List<Object?> get props => [animalId, extractedItemIds];
}

class MedicalDocumentAnimalEntity extends Equatable {
  final String id;
  final String name;
  final String? code;
  final String? species;
  final String? breed;
  final String? sex;
  final String? color;
  final String? birthdate;
  final String? age;
  final String? weight;
  final Map<String, String> fields;
  final Map<String, String> additionalDetails;

  const MedicalDocumentAnimalEntity({
    required this.id,
    required this.name,
    this.code,
    this.species,
    this.breed,
    this.sex,
    this.color,
    this.birthdate,
    this.age,
    this.weight,
    this.fields = const {},
    this.additionalDetails = const {},
  });

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    species,
    breed,
    sex,
    color,
    birthdate,
    age,
    weight,
    fields,
    additionalDetails,
  ];
}

class MedicalDocumentTutorEntity extends Equatable {
  final String name;
  final String identification;
  final String phoneNumber;
  final Map<String, String> fields;
  final Map<String, String> additionalDetails;

  const MedicalDocumentTutorEntity({
    required this.name,
    required this.identification,
    required this.phoneNumber,
    this.fields = const {},
    this.additionalDetails = const {},
  });

  @override
  List<Object?> get props => [
    name,
    identification,
    phoneNumber,
    fields,
    additionalDetails,
  ];
}

class MedicalDocumentEntity extends Equatable {
  final String id;
  final String documentCode;
  final List<String> animalIds;
  final String originalFileName;
  final String mimeType;
  final int fileSize;
  final MedicalDocumentStatus status;
  final MedicalDocumentCategory? requestedCategory;
  final MedicalDocumentCategory? primaryDetectedCategory;
  final List<DetectedMedicalDocumentCategoryEntity> detectedCategories;
  final MedicalDocumentClassificationOutcome? classificationOutcome;
  final Map<MedicalDocumentCategory, MedicalDocumentExtractionEntity>
  extractionsByCategory;
  final MedicalDocumentCategory? finalCategory;
  final MedicalDocumentExtractionEntity? validatedExtraction;
  final List<MedicalDocumentAssignmentEntity> assignments;
  final List<MedicalDocumentAnimalEntity> animalDetails;
  final MedicalDocumentTutorEntity? tutorDetails;
  final int version;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? reviewedAt;

  const MedicalDocumentEntity({
    required this.id,
    this.documentCode = '',
    required this.animalIds,
    required this.originalFileName,
    required this.mimeType,
    required this.fileSize,
    required this.status,
    this.requestedCategory,
    this.primaryDetectedCategory,
    this.detectedCategories = const [],
    this.classificationOutcome,
    this.extractionsByCategory = const {},
    this.finalCategory,
    this.validatedExtraction,
    this.assignments = const [],
    this.animalDetails = const [],
    this.tutorDetails,
    required this.version,
    this.createdAt,
    this.updatedAt,
    this.reviewedAt,
  });

  @override
  List<Object?> get props => [
    id,
    documentCode,
    animalIds,
    originalFileName,
    mimeType,
    fileSize,
    status,
    requestedCategory,
    primaryDetectedCategory,
    detectedCategories,
    classificationOutcome,
    extractionsByCategory,
    finalCategory,
    validatedExtraction,
    assignments,
    animalDetails,
    tutorDetails,
    version,
    createdAt,
    updatedAt,
    reviewedAt,
  ];
}
