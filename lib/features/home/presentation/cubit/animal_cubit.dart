import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/entities/create_animal_params.dart';
import 'package:animal_record/features/home/domain/usecases/create_animal_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/get_animals_by_owner_usecase.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';

class AnimalCubit extends Cubit<AnimalState> {
  final CreateAnimalUseCase createAnimalUseCase;
  final GetAnimalsByOwnerUseCase getAnimalsByOwnerUseCase;

  AnimalCubit({
    required this.createAnimalUseCase,
    required this.getAnimalsByOwnerUseCase,
  }) : super(AnimalInitial());

  /// Cached list so we can preserve it during create operations.
  List<AnimalEntity> _animals = [];

  List<AnimalEntity> get animals => _animals;

  Future<void> loadAnimals(String ownerId) async {
    emit(AnimalsLoading());

    final result = await getAnimalsByOwnerUseCase(ownerId);

    result.fold(
      (failure) => emit(AnimalError(failure.message)),
      (animals) {
        _animals = animals;
        emit(AnimalsLoaded(animals));
      },
    );
  }

  Future<void> createAnimal(CreateAnimalParams params) async {
    emit(AnimalCreating(existingAnimals: _animals));

    final result = await createAnimalUseCase(params);

    result.fold(
      (failure) => emit(AnimalError(failure.message, existingAnimals: _animals)),
      (animal) {
        _animals = [..._animals, animal];
        emit(AnimalCreated(animal, allAnimals: _animals));
      },
    );
  }

  /// Resets to the loaded state with existing animals.
  void resetToLoaded() {
    emit(AnimalsLoaded(_animals));
  }
}
