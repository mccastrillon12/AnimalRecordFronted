import 'dart:typed_data';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_ai_feedback.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_rejection_reason.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_field_catalog.dart';
import 'package:animal_record/features/medical_documents/domain/repositories/medical_documents_repository.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_file_loader.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_file_saver.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_contract_validator.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_write_access.dart';

class EnsureMedicalDocumentEditableUseCase {
  final MedicalDocumentWriteAccess writeAccess;

  const EnsureMedicalDocumentEditableUseCase(this.writeAccess);

  Future<void> call(MedicalDocumentEntity document, {String? animalId}) =>
      writeAccess.ensureWritable(
        animalIds: {...document.animalIds, if (animalId != null) animalId},
        documentIds: [document.id],
      );
}

class GetMedicalFieldCatalogUseCase {
  final MedicalDocumentsRepository repository;

  const GetMedicalFieldCatalogUseCase(this.repository);

  Future<MedicalFieldCatalog> call({
    required MedicalDocumentCategory category,
    String locale = 'es-CO',
  }) => repository.getFieldCatalog(category: category, locale: locale);
}

class AnalyzeMedicalDocumentUseCase {
  final MedicalDocumentsRepository repository;
  const AnalyzeMedicalDocumentUseCase(this.repository);
  Future<MedicalDocumentEntity> call(AnalyzeMedicalDocumentRequest request) {
    MedicalDocumentContractValidator.validateAnalysis(
      file: request.file,
      animalIds: request.animalIds,
    );
    return repository.analyze(request);
  }
}

class AnalyzeMedicalDocumentReplacementUseCase {
  final MedicalDocumentsRepository repository;

  const AnalyzeMedicalDocumentReplacementUseCase(this.repository);

  Future<MedicalDocumentEntity> call(
    String documentId,
    AnalyzeMedicalDocumentReplacementRequest request,
  ) {
    MedicalDocumentContractValidator.validateReplacementAnalysis(request);
    return repository.analyzeReplacement(documentId, request);
  }
}

class GetMedicalDocumentUseCase {
  final MedicalDocumentsRepository repository;
  const GetMedicalDocumentUseCase(this.repository);
  Future<MedicalDocumentEntity> call(String documentId) =>
      repository.getById(documentId);
}

class GetRelatedMedicalDocumentsUseCase {
  final MedicalDocumentsRepository repository;

  const GetRelatedMedicalDocumentsUseCase(this.repository);

  Future<List<MedicalDocumentEntity>> call(String documentId) =>
      repository.getRelatedDocuments(documentId);
}

class GetMedicalDocumentRejectionReasonsUseCase {
  final MedicalDocumentsRepository repository;

  const GetMedicalDocumentRejectionReasonsUseCase(this.repository);

  Future<List<MedicalDocumentRejectionReasonEntity>> call() =>
      repository.getRejectionReasons();
}

class SubmitMedicalDocumentAiFeedbackUseCase {
  final MedicalDocumentsRepository repository;

  const SubmitMedicalDocumentAiFeedbackUseCase(this.repository);

  Future<void> call(MedicalDocumentAiFeedback feedback) =>
      repository.submitAiFeedback(feedback);
}

class ReviewMedicalDocumentUseCase {
  final MedicalDocumentsRepository repository;
  const ReviewMedicalDocumentUseCase(this.repository);
  Future<MedicalDocumentEntity> call(
    String documentId,
    ReviewMedicalDocumentRequest request, {
    required List<String> originalAnimalIds,
  }) {
    MedicalDocumentContractValidator.validateReview(
      request: request,
      originalAnimalIds: originalAnimalIds,
    );
    return repository.review(documentId, request);
  }
}

class ReviewMedicalDocumentReplacementUseCase {
  final MedicalDocumentsRepository repository;

  const ReviewMedicalDocumentReplacementUseCase(this.repository);

  Future<List<MedicalDocumentEntity>> call(
    String documentId,
    ReviewMedicalDocumentReplacementRequest request,
  ) {
    MedicalDocumentContractValidator.validateReplacementReview(request);
    return repository.reviewReplacement(documentId, request);
  }
}

class GetAnimalMedicalDocumentsUseCase {
  final MedicalDocumentsRepository repository;
  const GetAnimalMedicalDocumentsUseCase(this.repository);
  Future<List<MedicalDocumentEntity>> call(
    String animalId, {
    MedicalDocumentCategory? category,
    bool forceRefresh = false,
  }) => repository.getByAnimal(
    animalId,
    category: category,
    forceRefresh: forceRefresh,
  );
}

class GetMedicalDocumentDownloadUriUseCase {
  final MedicalDocumentsRepository repository;
  const GetMedicalDocumentDownloadUriUseCase(this.repository);
  Future<Uri> call(String documentId) => repository.getDownloadUri(documentId);
}

class LoadMedicalDocumentOriginalUseCase {
  final MedicalDocumentsRepository repository;
  final MedicalDocumentFileLoader fileLoader;
  final AnimalTransferRepository? historicalRepository;

  const LoadMedicalDocumentOriginalUseCase({
    required this.repository,
    required this.fileLoader,
    this.historicalRepository,
  });

  Future<SharedFileEntity> call(MedicalDocumentEntity document) async {
    final history = document.historicalFile;
    if (document.readOnly && history == null) {
      throw const FormatException(
        'No se encontró el archivo en el expediente.',
      );
    }
    final historicalDownload = history == null
        ? null
        : await historicalRepository!.downloadHistoricalFileData(
            periodId: history.periodId,
            publicationHash: history.publicationHash,
            entryId: history.entryId,
            fileId: history.fileId,
          );
    final bytes =
        historicalDownload?.bytes ??
        await fileLoader.load(await repository.getDownloadUri(document.id));
    final fileName = historicalDownload?.fileName ?? document.originalFileName;
    final mimeType = historicalDownload?.mimeType ?? document.mimeType;
    return SharedFileEntity(
      path: '',
      name: fileName,
      mimeType: mimeType,
      type: _sharedFileType(mimeType, fileName),
      size: bytes.length,
      bytes: Uint8List.fromList(bytes),
    );
  }

  SharedFileType _sharedFileType(String mimeType, String fileName) {
    final normalizedMimeType = mimeType.trim().toLowerCase();
    final normalizedFileName = fileName.trim().toLowerCase();
    if (normalizedMimeType == 'application/pdf' ||
        normalizedFileName.endsWith('.pdf')) {
      return SharedFileType.pdf;
    }
    if (normalizedMimeType.startsWith('image/') ||
        RegExp(r'\.(png|jpe?g|tiff?)$').hasMatch(normalizedFileName)) {
      return SharedFileType.image;
    }
    return SharedFileType.unsupported;
  }
}

class DeleteMedicalDocumentUseCase {
  final MedicalDocumentsRepository repository;

  const DeleteMedicalDocumentUseCase(this.repository);

  Future<void> call(String animalId, String documentId, int documentVersion) {
    MedicalDocumentContractValidator.validateDocumentVersion(documentVersion);
    return repository.deleteDocument(animalId, documentId, documentVersion);
  }
}

class SaveMedicalDocumentOriginalUseCase {
  final MedicalDocumentFileSaver fileSaver;

  const SaveMedicalDocumentOriginalUseCase(this.fileSaver);

  Future<bool> call(MedicalDocumentFileSaveRequest request) {
    return fileSaver.save(request);
  }
}
