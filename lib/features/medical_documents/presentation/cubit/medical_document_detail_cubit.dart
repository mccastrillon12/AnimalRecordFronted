import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum MedicalDocumentDetailPhase {
  idle,
  loadingRelated,
  loadingOriginal,
  deleting,
  deleted,
}

class MedicalDocumentDetailState extends Equatable {
  final MedicalDocumentDetailPhase phase;
  final List<MedicalDocumentEntity> relatedDocuments;
  final String? message;

  const MedicalDocumentDetailState({
    this.phase = MedicalDocumentDetailPhase.idle,
    this.relatedDocuments = const [],
    this.message,
  });

  bool get isBusy =>
      phase == MedicalDocumentDetailPhase.loadingRelated ||
      phase == MedicalDocumentDetailPhase.loadingOriginal ||
      phase == MedicalDocumentDetailPhase.deleting;

  @override
  List<Object?> get props => [phase, relatedDocuments, message];
}

class MedicalDocumentDetailCubit extends Cubit<MedicalDocumentDetailState> {
  final GetRelatedMedicalDocumentsUseCase getRelatedDocumentsUseCase;
  final DeleteMedicalDocumentUseCase deleteDocumentUseCase;
  final LoadMedicalDocumentOriginalUseCase loadOriginalUseCase;

  MedicalDocumentDetailCubit({
    required this.getRelatedDocumentsUseCase,
    required this.deleteDocumentUseCase,
    required this.loadOriginalUseCase,
  }) : super(const MedicalDocumentDetailState());

  Future<List<MedicalDocumentEntity>?> loadRelatedDocuments(
    String documentId,
  ) async {
    emit(
      const MedicalDocumentDetailState(
        phase: MedicalDocumentDetailPhase.loadingRelated,
      ),
    );
    try {
      final documents = await getRelatedDocumentsUseCase(documentId);
      final immutable = List<MedicalDocumentEntity>.unmodifiable(documents);
      emit(MedicalDocumentDetailState(relatedDocuments: immutable));
      return immutable;
    } catch (error) {
      emit(MedicalDocumentDetailState(message: _message(error)));
      return null;
    }
  }

  Future<SharedFileEntity?> loadOriginalFile(
    MedicalDocumentEntity document,
  ) async {
    emit(
      MedicalDocumentDetailState(
        phase: MedicalDocumentDetailPhase.loadingOriginal,
        relatedDocuments: state.relatedDocuments,
      ),
    );
    try {
      final file = await loadOriginalUseCase(document);
      emit(
        MedicalDocumentDetailState(relatedDocuments: state.relatedDocuments),
      );
      return file;
    } catch (error) {
      emit(
        MedicalDocumentDetailState(
          relatedDocuments: state.relatedDocuments,
          message: _message(error),
        ),
      );
      return null;
    }
  }

  Future<bool> deleteDocument({
    required String animalId,
    required String documentId,
    required int documentVersion,
  }) async {
    emit(
      MedicalDocumentDetailState(
        phase: MedicalDocumentDetailPhase.deleting,
        relatedDocuments: state.relatedDocuments,
      ),
    );
    try {
      await deleteDocumentUseCase(animalId, documentId, documentVersion);
      emit(
        MedicalDocumentDetailState(
          phase: MedicalDocumentDetailPhase.deleted,
          relatedDocuments: state.relatedDocuments,
        ),
      );
      return true;
    } catch (error) {
      emit(
        MedicalDocumentDetailState(
          relatedDocuments: state.relatedDocuments,
          message: _message(error),
        ),
      );
      return false;
    }
  }

  String _message(Object error) => error.toString().replaceFirst(
    RegExp(r'^(Exception|ApiException):\s*'),
    '',
  );
}
