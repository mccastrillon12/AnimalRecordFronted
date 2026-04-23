import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/entities/create_animal_params.dart';
import 'package:animal_record/features/home/domain/entities/update_animal_params.dart';
import 'package:animal_record/features/home/domain/usecases/create_animal_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/get_animals_by_owner_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/update_animal_usecase.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';

class AnimalCubit extends Cubit<AnimalState> {
  final CreateAnimalUseCase createAnimalUseCase;
  final GetAnimalsByOwnerUseCase getAnimalsByOwnerUseCase;
  final UpdateAnimalUseCase updateAnimalUseCase;

  AnimalCubit({
    required this.createAnimalUseCase,
    required this.getAnimalsByOwnerUseCase,
    required this.updateAnimalUseCase,
  }) : super(AnimalInitial());

  /// Cached list so we can preserve it during create operations.
  List<AnimalEntity> _animals = [];

  /// The owner ID whose animals are currently loaded.
  String? _currentOwnerId;

  List<AnimalEntity> get animals => _animals;

  Future<void> loadAnimals(String ownerId) async {
    // If animals are already loaded for this same owner, skip the reload.
    if (_currentOwnerId == ownerId && state is AnimalsLoaded) return;

    _currentOwnerId = ownerId;
    emit(AnimalsLoading());

    final result = await getAnimalsByOwnerUseCase(ownerId);

    result.fold((failure) => emit(AnimalError(failure.message)), (animals) {
      _animals = animals;
      emit(AnimalsLoaded(animals));
    });
  }

  Future<void> createAnimal(CreateAnimalParams params) async {
    emit(AnimalCreating(existingAnimals: _animals));

    final result = await createAnimalUseCase(params);

    result.fold(
      (failure) =>
          emit(AnimalError(failure.message, existingAnimals: _animals)),
      (animal) {
        _animals = [..._animals, animal];
        emit(AnimalCreated(animal, allAnimals: _animals));
      },
    );
  }

  Future<void> updateAnimal(UpdateAnimalParams params) async {
    emit(AnimalUpdating(existingAnimals: _animals));

    final result = await updateAnimalUseCase(params);

    result.fold(
      (failure) =>
          emit(AnimalError(failure.message, existingAnimals: _animals)),
      (updatedAnimal) async {
        if (_currentOwnerId != null) {
          // Re-fetch to guarantee we have all backend-generated fields (like code, image, etc.)
          // especially since the API might just return a success boolean.
          final fetchResult = await getAnimalsByOwnerUseCase(_currentOwnerId!);
          fetchResult.fold(
            (l) {
              // Fallback if re-fetch fails
              _animals = _animals
                  .map((a) => a.id == updatedAnimal.id ? updatedAnimal : a)
                  .toList();
              emit(AnimalUpdated(updatedAnimal, allAnimals: _animals));
            },
            (fetchedAnimals) {
              _animals = fetchedAnimals;
              AnimalEntity realUpdated = updatedAnimal;
              try {
                realUpdated = _animals.firstWhere(
                  (a) => a.id == updatedAnimal.id,
                );
              } catch (_) {}

              emit(AnimalUpdated(realUpdated, allAnimals: _animals));
            },
          );
        } else {
          _animals = _animals
              .map((a) => a.id == updatedAnimal.id ? updatedAnimal : a)
              .toList();
          emit(AnimalUpdated(updatedAnimal, allAnimals: _animals));
        }
      },
    );
  }

  /// Resets to the loaded state with existing animals.
  void resetToLoaded() {
    emit(AnimalsLoaded(_animals));
  }

  /// Clears all cached data (call on logout).
  void reset() {
    _animals = [];
    _currentOwnerId = null;
    emit(AnimalInitial());
  }
}
