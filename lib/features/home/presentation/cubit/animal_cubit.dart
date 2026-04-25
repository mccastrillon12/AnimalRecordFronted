import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:animal_record/core/services/s3_upload_service.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/entities/create_animal_params.dart';
import 'package:animal_record/features/home/domain/entities/update_animal_params.dart';
import 'package:animal_record/features/home/domain/usecases/create_animal_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/get_animals_by_owner_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/update_animal_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/get_animal_picture_upload_url_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/confirm_animal_picture_usecase.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';

class AnimalCubit extends Cubit<AnimalState> {
  final CreateAnimalUseCase createAnimalUseCase;
  final GetAnimalsByOwnerUseCase getAnimalsByOwnerUseCase;
  final UpdateAnimalUseCase updateAnimalUseCase;
  final GetAnimalPictureUploadUrlUseCase getAnimalPictureUploadUrlUseCase;
  final ConfirmAnimalPictureUseCase confirmAnimalPictureUseCase;
  final S3UploadService s3UploadService;

  AnimalCubit({
    required this.createAnimalUseCase,
    required this.getAnimalsByOwnerUseCase,
    required this.updateAnimalUseCase,
    required this.getAnimalPictureUploadUrlUseCase,
    required this.confirmAnimalPictureUseCase,
    required this.s3UploadService,
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

  /// Uploads a profile picture for the given animal.
  ///
  /// Flow: compress → get presigned URL → upload to S3 → confirm with backend.
  Future<void> updateProfilePicture(String animalId, String imagePath) async {
    emit(AnimalPictureUploading(
      existingAnimals: _animals,
      animalId: animalId,
    ));

    try {
      // Step 1: Compress image locally
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imagePath,
        minWidth: 800,
        minHeight: 800,
        quality: 80,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) {
        emit(AnimalError(
          'No se pudo comprimir la imagen',
          existingAnimals: _animals,
        ));
        return;
      }

      const mimeType = 'image/jpeg';
      final fileSize = compressedBytes.length;

      // Step 2: Get presigned URL from backend
      final urlResult = await getAnimalPictureUploadUrlUseCase(
        animalId: animalId,
        mimeType: mimeType,
        fileSize: fileSize,
      );

      await urlResult.fold(
        (failure) async {
          emit(AnimalError(failure.message, existingAnimals: _animals));
        },
        (urlData) async {
          final uploadUrl = urlData['uploadUrl'] as String?;
          final finalUrl = urlData['finalUrl'] as String?;

          if (uploadUrl == null || finalUrl == null) {
            emit(AnimalError(
              'Respuesta inválida del servidor',
              existingAnimals: _animals,
            ));
            return;
          }

          // Step 3: Upload directly to S3
          await s3UploadService.uploadFileToS3(
            presignedUrl: uploadUrl,
            bytes: compressedBytes,
            mimeType: mimeType,
          );

          // Step 4: Confirm with backend
          final confirmResult = await confirmAnimalPictureUseCase(
            animalId: animalId,
            finalUrl: finalUrl,
          );

          await confirmResult.fold(
            (failure) async {
              emit(AnimalError(failure.message, existingAnimals: _animals));
            },
            (_) async {
              // Re-fetch animals to get the updated data
              if (_currentOwnerId != null) {
                final fetchResult =
                    await getAnimalsByOwnerUseCase(_currentOwnerId!);
                fetchResult.fold(
                  (l) {
                    // Fallback: manually update the local list
                    _updateAnimalPictureInList(animalId, finalUrl);
                  },
                  (fetchedAnimals) {
                    _animals = fetchedAnimals;
                  },
                );
              } else {
                _updateAnimalPictureInList(animalId, finalUrl);
              }

              // Find the updated animal
              AnimalEntity updatedAnimal;
              try {
                updatedAnimal = _animals.firstWhere((a) => a.id == animalId);
              } catch (_) {
                // Build a minimal placeholder — should not happen
                _updateAnimalPictureInList(animalId, finalUrl);
                updatedAnimal = _animals.firstWhere((a) => a.id == animalId);
              }

              emit(AnimalPictureUploaded(
                updatedAnimal,
                allAnimals: _animals,
              ));
            },
          );
        },
      );
    } catch (e) {
      emit(AnimalError(
        'Error inesperado: ${e.toString()}',
        existingAnimals: _animals,
      ));
    }
  }

  /// Deletes the profile picture for the given animal by sending an empty URL.
  Future<void> deleteProfilePicture(String animalId) async {
    emit(AnimalPictureUploading(
      existingAnimals: _animals,
      animalId: animalId,
    ));

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
            final fetchResult =
                await getAnimalsByOwnerUseCase(_currentOwnerId!);
            fetchResult.fold(
              (l) => _updateAnimalPictureInList(animalId, null),
              (fetchedAnimals) => _animals = fetchedAnimals,
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
      emit(AnimalError(
        'Error inesperado: ${e.toString()}',
        existingAnimals: _animals,
      ));
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
        );
      }
      return a;
    }).toList();
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
