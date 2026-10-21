import 'package:animal_record/features/auth/domain/entities/user_entity.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SharedFileAppProfile {
  final SharedFilePatientAnalysisEntity patient;
  final SharedFileTutorAnalysisEntity tutor;

  const SharedFileAppProfile({required this.patient, required this.tutor});
}

SharedFileAppProfile sharedFileAppProfile(
  BuildContext context,
  AnimalModel animal,
) {
  UserEntity? user;
  try {
    final state = context.read<AuthBloc>().state;
    if (state is AuthSuccess) user = state.user;
  } catch (_) {}
  return SharedFileAppProfile(
    patient: sharedFilePatientFromAnimal(animal),
    tutor: sharedFileTutorFromApp(user, animal),
  );
}

SharedFileAppProfile? sharedFileAppProfileByAnimalId(
  BuildContext context,
  String animalId,
) {
  try {
    final animals = context.read<AnimalCubit>().animals;
    final index = animals.indexWhere((animal) => animal.id == animalId);
    if (index < 0) return null;
    final animalEntity = animals[index];
    return sharedFileAppProfile(context, AnimalModel.fromEntity(animalEntity));
  } catch (_) {
    return null;
  }
}

SharedFilePatientAnalysisEntity sharedFilePatientFromAnimal(
  AnimalModel animal,
) {
  return SharedFilePatientAnalysisEntity(
    name: animal.name.trim(),
    recordId: animal.code.trim(),
    species: animal.family.trim(),
    breed: animal.breed?.trim() ?? '',
    sex: animal.sexDisplay.trim(),
    color: animal.colorAndMarkings?.trim() ?? '',
    age: animal.ageDisplay.trim(),
    weight: sharedFileWeight(animal.weight),
  );
}

SharedFileTutorAnalysisEntity sharedFileTutorFromApp(
  UserEntity? user,
  AnimalModel animal,
) {
  return SharedFileTutorAnalysisEntity(
    name: _firstNotEmpty([user?.name, animal.ownerName]),
    identification: _identification(
      user?.identificationType,
      user?.identificationNumber,
    ),
    phoneNumber: _phone(user?.cellPhone),
    email: user?.email.trim() ?? '',
  );
}

String sharedFileWeight(double? value) {
  if (value == null) return '';
  final formatted = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
  return '$formatted kg';
}

String _firstNotEmpty(List<String?> values) {
  for (final value in values) {
    final normalized = value?.trim() ?? '';
    if (normalized.isNotEmpty) return normalized;
  }
  return '';
}

String _identification(String? rawType, String? rawNumber) {
  final type = _identificationType(rawType);
  final number = rawNumber?.trim() ?? '';
  return [type, number].where((value) => value.isNotEmpty).join(' ');
}

String _identificationType(String? value) {
  final raw = value?.trim() ?? '';
  final normalized = raw.replaceAll(RegExp(r'[.\s]'), '').toUpperCase();
  return switch (normalized) {
    'CC' => 'C.C.',
    'CE' => 'C.E.',
    'TI' => 'T.I.',
    _ => raw.toUpperCase(),
  };
}

String _phone(String? value) {
  final original = value?.trim() ?? '';
  if (original.isEmpty) return '';
  var digits = original.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0057') && digits.length > 10) {
    digits = digits.substring(4);
  } else if (digits.startsWith('57') && digits.length > 10) {
    digits = digits.substring(2);
  }
  return digits.isEmpty ? original : '(+57) $digits';
}
