import 'package:equatable/equatable.dart';

enum MedicalDocumentCategory {
  prescription('PRESCRIPTION', 'Fórmula médica'),
  medicalOrder('MEDICAL_ORDER', 'Orden médica'),
  referral('REFERRAL', 'Remisión médica'),
  vaccinationCard('VACCINATION_CARD', 'Carné de vacunas'),
  clinicalHistory('CLINICAL_HISTORY', 'Historia clínica'),
  other('OTHER', 'Otro');

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

class MedicalDocumentExtractionEntity extends Equatable {
  final MedicalDocumentCategory documentType;
  final double? documentTypeConfidence;
  final String? summary;
  final String? documentDate;
  final Map<String, dynamic>? issuer;
  final List<String> patientHints;
  final List<MedicalDocumentItemEntity> diagnoses;
  final List<MedicalDocumentItemEntity> medications;
  final List<MedicalDocumentItemEntity> vaccinations;
  final List<MedicalDocumentItemEntity> medicalOrders;
  final Map<String, dynamic>? clinicalHistory;
  final List<MedicalDocumentItemEntity> diagnosticResults;
  final Map<String, dynamic>? referral;
  final Map<String, dynamic> additionalFields;
  final List<String> warnings;

  const MedicalDocumentExtractionEntity({
    required this.documentType,
    this.documentTypeConfidence,
    this.summary,
    this.documentDate,
    this.issuer,
    this.patientHints = const [],
    this.diagnoses = const [],
    this.medications = const [],
    this.vaccinations = const [],
    this.medicalOrders = const [],
    this.clinicalHistory,
    this.diagnosticResults = const [],
    this.referral,
    this.additionalFields = const {},
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
  ];

  MedicalDocumentExtractionEntity copyWith({
    MedicalDocumentCategory? documentType,
    double? documentTypeConfidence,
    String? summary,
    String? documentDate,
    Map<String, dynamic>? issuer,
    List<String>? patientHints,
    List<MedicalDocumentItemEntity>? diagnoses,
    List<MedicalDocumentItemEntity>? medications,
    List<MedicalDocumentItemEntity>? vaccinations,
    List<MedicalDocumentItemEntity>? medicalOrders,
    Map<String, dynamic>? clinicalHistory,
    List<MedicalDocumentItemEntity>? diagnosticResults,
    Map<String, dynamic>? referral,
    Map<String, dynamic>? additionalFields,
    List<String>? warnings,
  }) {
    return MedicalDocumentExtractionEntity(
      documentType: documentType ?? this.documentType,
      documentTypeConfidence:
          documentTypeConfidence ?? this.documentTypeConfidence,
      summary: summary ?? this.summary,
      documentDate: documentDate ?? this.documentDate,
      issuer: issuer ?? this.issuer,
      patientHints: patientHints ?? this.patientHints,
      diagnoses: diagnoses ?? this.diagnoses,
      medications: medications ?? this.medications,
      vaccinations: vaccinations ?? this.vaccinations,
      medicalOrders: medicalOrders ?? this.medicalOrders,
      clinicalHistory: clinicalHistory ?? this.clinicalHistory,
      diagnosticResults: diagnosticResults ?? this.diagnosticResults,
      referral: referral ?? this.referral,
      additionalFields: additionalFields ?? this.additionalFields,
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
      issuer: issuer,
      patientHints: patientHints,
      diagnoses: switch (category) {
        MedicalDocumentCategory.prescription ||
        MedicalDocumentCategory.medicalOrder ||
        MedicalDocumentCategory.referral ||
        MedicalDocumentCategory.clinicalHistory => diagnoses,
        _ => const [],
      },
      medications: switch (category) {
        MedicalDocumentCategory.prescription ||
        MedicalDocumentCategory.referral => medications,
        _ => const [],
      },
      vaccinations: category == MedicalDocumentCategory.vaccinationCard
          ? vaccinations
          : const [],
      medicalOrders: category == MedicalDocumentCategory.medicalOrder
          ? medicalOrders
          : const [],
      clinicalHistory: category == MedicalDocumentCategory.clinicalHistory
          ? clinicalHistory
          : null,
      diagnosticResults:
          category == MedicalDocumentCategory.referral ||
              category == MedicalDocumentCategory.clinicalHistory
          ? diagnosticResults
          : const [],
      referral: category == MedicalDocumentCategory.referral ? referral : null,
      additionalFields: additionalFields,
      warnings: warnings,
    );
  }

  @override
  List<Object?> get props => [
    documentType,
    documentTypeConfidence,
    summary,
    documentDate,
    issuer,
    patientHints,
    diagnoses,
    medications,
    vaccinations,
    medicalOrders,
    clinicalHistory,
    diagnosticResults,
    referral,
    additionalFields,
    warnings,
  ];
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
