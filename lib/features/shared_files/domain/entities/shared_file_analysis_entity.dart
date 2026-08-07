import 'package:equatable/equatable.dart';

class SharedFileAnalysisEntity extends Equatable {
  final String documentType;
  final String documentNumber;
  final DateTime date;
  final String originalFileName;
  final SharedFilePatientAnalysisEntity patient;
  final SharedFileTutorAnalysisEntity tutor;
  final List<SharedFileMedicationAnalysisEntity> medications;
  final String? observations;

  const SharedFileAnalysisEntity({
    required this.documentType,
    required this.documentNumber,
    required this.date,
    required this.originalFileName,
    required this.patient,
    required this.tutor,
    this.medications = const [],
    this.observations,
  });

  @override
  List<Object?> get props => [
    documentType,
    documentNumber,
    date,
    originalFileName,
    patient,
    tutor,
    medications,
    observations,
  ];
}

class SharedFileTutorAnalysisEntity extends Equatable {
  final String name;
  final String identification;
  final String phoneNumber;

  const SharedFileTutorAnalysisEntity({
    required this.name,
    required this.identification,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [name, identification, phoneNumber];
}

class SharedFilePatientAnalysisEntity extends Equatable {
  final String name;
  final String recordId;
  final String species;
  final String breed;
  final String age;
  final String weight;

  const SharedFilePatientAnalysisEntity({
    required this.name,
    required this.recordId,
    required this.species,
    required this.breed,
    required this.age,
    required this.weight,
  });

  @override
  List<Object?> get props => [name, recordId, species, breed, age, weight];
}

class SharedFileMedicationAnalysisEntity extends Equatable {
  final String name;
  final int quantity;
  final String instructions;
  final String? originalUrl;

  const SharedFileMedicationAnalysisEntity({
    required this.name,
    required this.quantity,
    required this.instructions,
    this.originalUrl,
  });

  @override
  List<Object?> get props => [name, quantity, instructions, originalUrl];
}
