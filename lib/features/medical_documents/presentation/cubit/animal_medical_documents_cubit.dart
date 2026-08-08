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

  AnimalMedicalDocumentsCubit({required this.getDocumentsUseCase})
    : super(AnimalMedicalDocumentsInitial());

  Future<void> load(
    String animalId, {
    MedicalDocumentCategory? category,
  }) async {
    emit(AnimalMedicalDocumentsLoading());
    try {
      emit(
        AnimalMedicalDocumentsLoaded(
          await getDocumentsUseCase(animalId, category: category),
          category: category,
        ),
      );
    } catch (error) {
      emit(
        AnimalMedicalDocumentsError(
          error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
