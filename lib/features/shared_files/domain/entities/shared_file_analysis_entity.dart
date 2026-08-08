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
  final String? observations;

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
    this.observations,
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
      observations: observations,
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
    observations,
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

class SharedFileMedicationAnalysisEntity extends Equatable {
  final String name;
  final int? quantity;
  final String instructions;
  final String? originalUrl;

  const SharedFileMedicationAnalysisEntity({
    required this.name,
    this.quantity,
    required this.instructions,
    this.originalUrl,
  });

  SharedFileMedicationAnalysisEntity withOriginalUrl(String originalUrl) {
    return SharedFileMedicationAnalysisEntity(
      name: name,
      quantity: quantity,
      instructions: instructions,
      originalUrl: originalUrl,
    );
  }

  @override
  List<Object?> get props => [name, quantity, instructions, originalUrl];
}
