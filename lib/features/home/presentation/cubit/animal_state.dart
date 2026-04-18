import 'package:equatable/equatable.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';

abstract class AnimalState extends Equatable {
  const AnimalState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no data loaded yet.
class AnimalInitial extends AnimalState {}

/// Animals list is being fetched.
class AnimalsLoading extends AnimalState {}

/// Animals list loaded successfully.
class AnimalsLoaded extends AnimalState {
  final List<AnimalEntity> animals;

  const AnimalsLoaded(this.animals);

  @override
  List<Object?> get props => [animals];
}

/// A single animal is being created (POST in progress).
class AnimalCreating extends AnimalState {
  final List<AnimalEntity> existingAnimals;

  const AnimalCreating({this.existingAnimals = const []});

  @override
  List<Object?> get props => [existingAnimals];
}

/// A single animal was created successfully.
class AnimalCreated extends AnimalState {
  final AnimalEntity animal;
  final List<AnimalEntity> allAnimals;

  const AnimalCreated(this.animal, {this.allAnimals = const []});

  @override
  List<Object?> get props => [animal, allAnimals];
}

/// Error state.
class AnimalError extends AnimalState {
  final String message;
  final List<AnimalEntity> existingAnimals;

  const AnimalError(this.message, {this.existingAnimals = const []});

  @override
  List<Object?> get props => [message, existingAnimals];
}
