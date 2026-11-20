import 'package:animal_record/features/home/domain/usecases/animal_history_usecases.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/entities/create_animal_params.dart';
import 'package:animal_record/features/home/domain/entities/update_animal_params.dart';
import 'package:animal_record/features/home/domain/usecases/create_animal_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/get_animals_by_owner_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/update_animal_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/confirm_animal_picture_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/get_animal_by_id_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/search_animals_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/upload_animal_picture_usecase.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';

class AnimalCubit extends Cubit<AnimalState> {
  final CreateAnimalUseCase createAnimalUseCase;
  final GetAnimalsByOwnerUseCase getAnimalsByOwnerUseCase;
  final GetAnimalByIdUseCase getAnimalByIdUseCase;
  final UpdateAnimalUseCase updateAnimalUseCase;
  final ConfirmAnimalPictureUseCase confirmAnimalPictureUseCase;
  final SearchAnimalsUseCase searchAnimalsUseCase;
  final UploadAnimalPictureUseCase uploadAnimalPictureUseCase;
  final LoadHistoricalAnimalUseCase? historicalAnimalLoader;

  AnimalCubit({
    required this.createAnimalUseCase,
    required this.getAnimalsByOwnerUseCase,
    required this.getAnimalByIdUseCase,
    required this.updateAnimalUseCase,
    required this.confirmAnimalPictureUseCase,
    required this.searchAnimalsUseCase,
    required this.uploadAnimalPictureUseCase,
    this.historicalAnimalLoader,
  }) : super(AnimalInitial());

  /// Cached list so we can preserve it during create operations.
  List<AnimalEntity> _animals = [];

  /// The owner ID whose animals are currently loaded.
  String? _currentOwnerId;
  int _ownerLoadGeneration = 0;
  bool _ownerLoadInProgress = false;

  String? get currentOwnerId => _currentOwnerId;

  List<AnimalEntity> get animals => _animals;

  Future<void> loadAnimals(String ownerId, {bool forceRefresh = false}) async {
    final sameOwner = _currentOwnerId == ownerId;
    if (!forceRefresh &&
        sameOwner &&
        (_ownerLoadInProgress || state is AnimalsLoaded)) {
      return;
    }

    final generation = ++_ownerLoadGeneration;
    _ownerLoadInProgress = true;
    if (!sameOwner) _animals = [];
    _currentOwnerId = ownerId;
    historicalAnimalLoader?.useAccount(ownerId);
    emit(AnimalsLoading());

    final result = await getAnimalsByOwnerUseCase(ownerId);
    if (isClosed || generation != _ownerLoadGeneration) return;
    _ownerLoadInProgress = false;

    result.fold(
      (failure) =>
          emit(AnimalError(failure.message, existingAnimals: _animals)),
      (animals) {
        _animals = _withCachedHistory(animals);
        emit(AnimalsLoaded(_animals));
        unawaited(_prefetchHistory(generation));
      },
    );
  }

  Future<void> searchAnimals(Map<String, dynamic> queryParams) async {
    emit(AnimalsLoading());

    // If an ownerId is set in the cubit, ensure we include it in the query so we only search their animals
    if (_currentOwnerId != null && !queryParams.containsKey('ownerId')) {
      queryParams['ownerId'] = _currentOwnerId;
    }

    debugPrint('🔍 searchAnimals queryParams: $queryParams');

    final result = await searchAnimalsUseCase(queryParams);

    result.fold(
      (failure) {
        emit(AnimalError(failure.message, existingAnimals: _animals));
      },
      (animals) {
        _animals = _withCachedHistory(animals);
        emit(AnimalsLoaded(_animals));
        unawaited(_prefetchHistory(_ownerLoadGeneration));
      },
    );
  }

  Future<void> loadAnimalDetails(String animalId) async {
    if (_animals.any(
      (animal) => animal.id == animalId && animal.isHistorical,
    )) {
      return;
    }
    final generation = _ownerLoadGeneration;
    final result = await getAnimalByIdUseCase(animalId);
    if (isClosed || generation != _ownerLoadGeneration) return;

    result.fold(
      (failure) =>
          emit(AnimalError(failure.message, existingAnimals: _animals)),
      (animal) {
        // Update the animal in the local cache
        _animals = List.of(_animals);
        final index = _animals.indexWhere(
          (a) => a.id == animal.id && !a.isHistorical,
        );
        if (index != -1) {
          _animals[index] = animal.withOwnershipAccessFrom(_animals[index]);
        } else {
          _animals.add(animal);
        }

        // Just emit loaded state so the UI rebuilds without showing a success message
        emit(AnimalsLoaded(_animals));
      },
    );
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
    if (!_allowWrite(params.id)) return;
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
              _animals = _withCachedHistory(fetchedAnimals);
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

  /// Uploads a profile picture for the given animal.
  ///
  /// The upload workflow is coordinated by [UploadAnimalPictureUseCase].
  Future<void> updateProfilePicture(String animalId, String imagePath) async {
    if (!_allowWrite(animalId)) return;
    emit(AnimalPictureUploading(existingAnimals: _animals, animalId: animalId));

    try {
      final result = await uploadAnimalPictureUseCase(
        animalId: animalId,
        imagePath: imagePath,
      );

      await result.fold(
        (failure) async {
          emit(AnimalError(failure.message, existingAnimals: _animals));
        },
        (finalUrl) async {
          // Re-fetch animals to get the updated data.
          if (_currentOwnerId != null) {
            final fetchResult = await getAnimalsByOwnerUseCase(
              _currentOwnerId!,
            );
            fetchResult.fold(
              (failure) {
                // Preserve the previous fallback when the refresh fails.
                _updateAnimalPictureInList(animalId, finalUrl);
              },
              (fetchedAnimals) {
                _animals = _withCachedHistory(fetchedAnimals);
              },
            );
          } else {
            _updateAnimalPictureInList(animalId, finalUrl);
          }

          AnimalEntity updatedAnimal;
          try {
            updatedAnimal = _animals.firstWhere((a) => a.id == animalId);
          } catch (_) {
            _updateAnimalPictureInList(animalId, finalUrl);
            updatedAnimal = _animals.firstWhere((a) => a.id == animalId);
          }

          emit(AnimalPictureUploaded(updatedAnimal, allAnimals: _animals));
        },
      );
    } catch (e) {
      emit(
        AnimalError(
          'Error inesperado: ${e.toString()}.',
          existingAnimals: _animals,
        ),
      );
    }
  }

  /// Deletes the profile picture for the given animal by sending an empty URL.
  Future<void> deleteProfilePicture(String animalId) async {
    if (!_allowWrite(animalId)) return;
    emit(AnimalPictureUploading(existingAnimals: _animals, animalId: animalId));

    try {
      final result = await confirmAnimalPictureUseCase(
        animalId: animalId,
        finalUrl: '',
      );

      await result.fold(
        (failure) async {
          emit(AnimalError(failure.message, existingAnimals: _animals));
        },
        (_) async {
          // Re-fetch animals to get the updated data
          if (_currentOwnerId != null) {
            final fetchResult = await getAnimalsByOwnerUseCase(
              _currentOwnerId!,
            );
            fetchResult.fold(
              (l) => _updateAnimalPictureInList(animalId, null),
              (fetchedAnimals) => _animals = _withCachedHistory(fetchedAnimals),
            );
          } else {
            _updateAnimalPictureInList(animalId, null);
          }

          AnimalEntity updatedAnimal;
          try {
            updatedAnimal = _animals.firstWhere((a) => a.id == animalId);
          } catch (_) {
            _updateAnimalPictureInList(animalId, null);
            updatedAnimal = _animals.firstWhere((a) => a.id == animalId);
          }

          emit(AnimalPictureUploaded(updatedAnimal, allAnimals: _animals));
        },
      );
    } catch (e) {
      emit(
        AnimalError(
          'Error inesperado: ${e.toString()}.',
          existingAnimals: _animals,
        ),
      );
    }
  }

  /// Helper to manually update the profilePictureUrl in the cached list.
  void _updateAnimalPictureInList(String animalId, String? url) {
    _animals = _animals.map((a) {
      if (a.id == animalId) {
        return AnimalEntity(
          id: a.id,
          name: a.name,
          code: a.code,
          species: a.species,
          breed: a.breed,
          sex: a.sex,
          reproductiveStatus: a.reproductiveStatus,
          birthdate: a.birthdate,
          hasChip: a.hasChip,
          isAssociationMember: a.isAssociationMember,
          temperament: a.temperament,
          diagnosis: a.diagnosis,
          ownerId: a.ownerId,
          profilePictureUrl: url,
          weight: a.weight,
          colorAndMarkings: a.colorAndMarkings,
          allergies: a.allergies,
          housingType: a.housingType,
          purpose: a.purpose,
          feedingType: a.feedingType,
          birthType: a.birthType,
          birthCondition: a.birthCondition,
          otherDiagnosisDetail: a.otherDiagnosisDetail,
          isActive: a.isActive,
          deactivationReason: a.deactivationReason,
          transferStatus: a.transferStatus,
          readOnly: a.readOnly,
          ownershipHistory: a.ownershipHistory,
          identificationType: a.identificationType,
          identificationNumber: a.identificationNumber,
          registrationAssociations: a.registrationAssociations,
          isAdopted: a.isAdopted,
          adoptionSource: a.adoptionSource,
          adoptionPlaceName: a.adoptionPlaceName,
          unknownBirthDate: a.unknownBirthDate,
          approximateAgeMinMonths: a.approximateAgeMinMonths,
          approximateAgeMaxMonths: a.approximateAgeMaxMonths,
          nameHistory: a.nameHistory,
          ownerHistory: a.ownerHistory,
          createdAt: a.createdAt,
          updatedAt: a.updatedAt,
          ownerName: a.ownerName,
        );
      }
      return a;
    }).toList();
  }

  bool _allowWrite(String animalId) {
    final matches = _animals.where((animal) => animal.id == animalId);
    if (matches.isEmpty || matches.any((animal) => animal.canWrite)) {
      return true;
    }
    emit(
      AnimalError('El animal es de solo lectura.', existingAnimals: _animals),
    );
    return false;
  }

  List<AnimalEntity> _withCachedHistory(Iterable<AnimalEntity> animals) =>
      uniqueAnimalCards(animals).map((animal) {
        return historicalAnimalLoader?.cached(animal, includeEntries: false) ??
            animal;
      }).toList();

  Future<void> _prefetchHistory(int generation) async {
    final loader = historicalAnimalLoader;
    if (loader == null) return;
    final cards = _animals
        .where(
          (animal) => animal.isHistorical && animal.ownershipHistory != null,
        )
        .toList();
    var index = 0;
    Future<void> worker() async {
      while (!isClosed &&
          generation == _ownerLoadGeneration &&
          index < cards.length) {
        final card = cards[index++];
        try {
          final loaded = await loader(
            card,
            preloadPhoto: true,
            includeEntries: false,
          );
          if (isClosed || generation != _ownerLoadGeneration) return;
          _animals = _animals
              .map(
                (animal) =>
                    animal.cardKey == card.cardKey &&
                        animal.ownershipHistory?.publicationHash ==
                            loaded.ownershipHistory?.publicationHash
                    ? loaded
                    : animal,
              )
              .toList();
          // Do not interrupt an edit/upload in progress with a background read.
          if (state is AnimalsLoaded) emit(AnimalsLoaded(_animals));
        } catch (_) {
          // A failed prefetch can be retried when this particular card is opened.
        }
      }
    }

    await Future.wait(List.generate(cards.length.clamp(0, 3), (_) => worker()));
  }

  /// Resets to the loaded state with existing animals.
  void resetToLoaded() {
    emit(AnimalsLoaded(_animals));
  }

  /// Clears all cached data (call on logout).
  void reset() {
    ++_ownerLoadGeneration;
    _ownerLoadInProgress = false;
    _animals = [];
    _currentOwnerId = null;
    historicalAnimalLoader?.clear();
    emit(AnimalInitial());
  }
}
