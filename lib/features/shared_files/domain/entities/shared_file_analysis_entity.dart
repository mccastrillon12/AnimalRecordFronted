import 'package:equatable/equatable.dart';

class SharedFileAnalysisEntity extends Equatable {
  final String documentType;
  final String documentNumber;
  final DateTime? date;
  final String? sourceDateText;
  final String originalFileName;
  final SharedFilePatientAnalysisEntity patient;
  final SharedFileTutorAnalysisEntity tutor;
  final SharedFileVeterinarianAnalysisEntity? veterinarian;
  final String? itemsTitle;
  final List<SharedFileMedicationAnalysisEntity> medications;
  final List<SharedFileAnalysisSectionEntity> sections;
  final String? observations;
  final String? originalUrl;

  const SharedFileAnalysisEntity({
    required this.documentType,
    required this.documentNumber,
    required this.date,
    this.sourceDateText,
    required this.originalFileName,
    required this.patient,
    required this.tutor,
    this.veterinarian,
    this.itemsTitle,
    this.medications = const [],
    this.sections = const [],
    this.observations,
    this.originalUrl,
  });

  SharedFileAnalysisEntity withMedications(
    List<SharedFileMedicationAnalysisEntity> medications,
  ) {
    return SharedFileAnalysisEntity(
      documentType: documentType,
      documentNumber: documentNumber,
      date: date,
      sourceDateText: sourceDateText,
      originalFileName: originalFileName,
      patient: patient,
      tutor: tutor,
      veterinarian: veterinarian,
      itemsTitle: itemsTitle,
      medications: medications,
      sections: sections,
      observations: observations,
      originalUrl: originalUrl,
    );
  }

  SharedFileAnalysisEntity withOriginalUrl(String value) {
    return SharedFileAnalysisEntity(
      documentType: documentType,
      documentNumber: documentNumber,
      date: date,
      sourceDateText: sourceDateText,
      originalFileName: originalFileName,
      patient: patient,
      tutor: tutor,
      veterinarian: veterinarian,
      itemsTitle: itemsTitle,
      medications: medications
          .map((medication) => medication.withOriginalUrl(value))
          .toList(growable: false),
      sections: sections,
      observations: observations,
      originalUrl: value,
    );
  }

  @override
  List<Object?> get props => [
    documentType,
    documentNumber,
    date,
    sourceDateText,
    originalFileName,
    patient,
    tutor,
    veterinarian,
    itemsTitle,
    medications,
    sections,
    observations,
    originalUrl,
  ];
}

class SharedFileVeterinarianAnalysisEntity extends Equatable {
  final String name;
  final String clinic;
  final String professionalId;
  final List<SharedFileAnalysisDetailEntity> additionalDetails;

  const SharedFileVeterinarianAnalysisEntity({
    required this.name,
    required this.clinic,
    required this.professionalId,
    this.additionalDetails = const [],
  });

  bool get hasData =>
      name.trim().isNotEmpty ||
      clinic.trim().isNotEmpty ||
      professionalId.trim().isNotEmpty ||
      additionalDetails.any((detail) => detail.hasData);

  @override
  List<Object?> get props => [name, clinic, professionalId, additionalDetails];
}

class SharedFileTutorAnalysisEntity extends Equatable {
  final String name;
  final String identification;
  final String phoneNumber;
  final List<SharedFileAnalysisDetailEntity> additionalDetails;

  const SharedFileTutorAnalysisEntity({
    required this.name,
    required this.identification,
    required this.phoneNumber,
    this.additionalDetails = const [],
  });

  bool get hasData =>
      name.trim().isNotEmpty ||
      identification.trim().isNotEmpty ||
      phoneNumber.trim().isNotEmpty ||
      additionalDetails.any((detail) => detail.hasData);

  @override
  List<Object?> get props => [
    name,
    identification,
    phoneNumber,
    additionalDetails,
  ];
}

class SharedFilePatientAnalysisEntity extends Equatable {
  final String name;
  final String recordId;
  final String species;
  final String breed;
  final String sex;
  final String color;
  final String age;
  final String weight;
  final List<SharedFileAnalysisDetailEntity> additionalDetails;

  const SharedFilePatientAnalysisEntity({
    required this.name,
    required this.recordId,
    required this.species,
    required this.breed,
    this.sex = '',
    this.color = '',
    required this.age,
    required this.weight,
    this.additionalDetails = const [],
  });

  bool get hasData =>
      name.trim().isNotEmpty ||
      recordId.trim().isNotEmpty ||
      species.trim().isNotEmpty ||
      breed.trim().isNotEmpty ||
      sex.trim().isNotEmpty ||
      color.trim().isNotEmpty ||
      age.trim().isNotEmpty ||
      weight.trim().isNotEmpty ||
      additionalDetails.any((detail) => detail.hasData);

  @override
  List<Object?> get props => [
    name,
    recordId,
    species,
    breed,
    sex,
    color,
    age,
    weight,
    additionalDetails,
  ];
}

class SharedFileAnalysisDetailEntity extends Equatable {
  final String label;
  final String value;

  const SharedFileAnalysisDetailEntity({
    required this.label,
    required this.value,
  });

  bool get hasData => label.trim().isNotEmpty && value.trim().isNotEmpty;

  @override
  List<Object?> get props => [label, value];
}

class SharedFileAnalysisSectionEntity extends Equatable {
  final String title;
  final List<SharedFileAnalysisDetailEntity> details;
  final String? body;

  const SharedFileAnalysisSectionEntity({
    required this.title,
    this.details = const [],
    this.body,
  });

  bool get hasData =>
      title.trim().isNotEmpty &&
      (details.any((detail) => detail.hasData) ||
          (body?.trim().isNotEmpty ?? false));

  @override
  List<Object?> get props => [title, details, body];
}

class SharedFileMedicationAnalysisEntity extends Equatable {
  final String name;
  final String? groupTitle;
  final int? quantity;
  final String instructions;
  final List<SharedFileAnalysisDetailEntity> details;
  final String? originalUrl;

  const SharedFileMedicationAnalysisEntity({
    required this.name,
    this.groupTitle,
    this.quantity,
    required this.instructions,
    this.details = const [],
    this.originalUrl,
  });

  SharedFileMedicationAnalysisEntity withOriginalUrl(String originalUrl) {
    return SharedFileMedicationAnalysisEntity(
      name: name,
      groupTitle: groupTitle,
      quantity: quantity,
      instructions: instructions,
      details: details,
      originalUrl: originalUrl,
    );
  }

  @override
  List<Object?> get props => [
    name,
    groupTitle,
    quantity,
    instructions,
    details,
    originalUrl,
  ];
}
