import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class AnimalMedicalDocumentsState extends Equatable {
  const AnimalMedicalDocumentsState();
  @override
  List<Object?> get props => [];
}

class AnimalMedicalDocumentsInitial extends AnimalMedicalDocumentsState {}

class AnimalMedicalDocumentsLoading extends AnimalMedicalDocumentsState {}

class AnimalMedicalDocumentsLoaded extends AnimalMedicalDocumentsState {
  final MedicalDocumentCategory? category;
  final List<MedicalDocumentEntity> documents;
  const AnimalMedicalDocumentsLoaded(this.documents, {this.category});
  @override
  List<Object?> get props => [category, documents];
}

class AnimalMedicalDocumentsError extends AnimalMedicalDocumentsState {
  final String message;
  const AnimalMedicalDocumentsError(this.message);
  @override
  List<Object?> get props => [message];
}

class AnimalMedicalDocumentsCubit extends Cubit<AnimalMedicalDocumentsState> {
  final GetAnimalMedicalDocumentsUseCase getDocumentsUseCase;
  String? _loadedAnimalId;
  MedicalDocumentCategory? _loadedCategory;

  AnimalMedicalDocumentsCubit({required this.getDocumentsUseCase})
    : super(AnimalMedicalDocumentsInitial());

  Future<void> load(String animalId, {MedicalDocumentCategory? category}) =>
      _load(animalId, category: category, preserveExisting: false);

  /// Refreshes the list after an accepted upload without replacing documents
  /// that are already visible for the same animal and category.
  Future<void> refreshAfterUpload(
    String animalId, {
    MedicalDocumentCategory? category,
  }) => _load(animalId, category: category, preserveExisting: true);

  Future<void> _load(
    String animalId, {
    required MedicalDocumentCategory? category,
    required bool preserveExisting,
  }) async {
    if (isClosed) return;

    final previousDocuments =
        preserveExisting &&
            _loadedAnimalId == animalId &&
            _loadedCategory == category &&
            state is AnimalMedicalDocumentsLoaded
        ? (state as AnimalMedicalDocumentsLoaded).documents
        : const <MedicalDocumentEntity>[];
    emit(AnimalMedicalDocumentsLoading());
    try {
      final fetchedDocuments = await getDocumentsUseCase(
        animalId,
        category: category,
        forceRefresh: preserveExisting,
      );
      if (isClosed) return;

      final documents = preserveExisting
          ? _mergeDocuments(fetchedDocuments, previousDocuments)
          : fetchedDocuments;
      _loadedAnimalId = animalId;
      _loadedCategory = category;
      emit(AnimalMedicalDocumentsLoaded(documents, category: category));
    } catch (error) {
      if (isClosed) return;

      emit(
        AnimalMedicalDocumentsError(
          error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  List<MedicalDocumentEntity> _mergeDocuments(
    List<MedicalDocumentEntity> fetched,
    List<MedicalDocumentEntity> previous,
  ) {
    final fetchedIds = fetched.map((document) => document.id).toSet();
    return List.unmodifiable([
      ...fetched,
      for (final document in previous)
        if (!fetchedIds.contains(document.id)) document,
    ]);
  }
}
