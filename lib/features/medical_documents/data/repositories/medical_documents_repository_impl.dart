import 'package:animal_record/features/medical_documents/data/datasources/medical_documents_remote_datasource.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_ai_feedback.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_rejection_reason.dart';
import 'package:animal_record/features/medical_documents/domain/repositories/medical_documents_repository.dart';

class MedicalDocumentsRepositoryImpl implements MedicalDocumentsRepository {
  final MedicalDocumentsRemoteDataSource remoteDataSource;

  final Map<_MedicalDocumentsCacheKey, List<MedicalDocumentEntity>> _cache = {};
  final Map<_MedicalDocumentsCacheKey, Future<List<MedicalDocumentEntity>>>
  _inFlight = {};
  final Map<_MedicalDocumentsCacheKey, int> _cacheGenerations = {};
  List<MedicalDocumentRejectionReasonEntity>? _rejectionReasons;
  Future<List<MedicalDocumentRejectionReasonEntity>>? _rejectionReasonsLoad;

  MedicalDocumentsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<MedicalDocumentEntity> analyze(
    AnalyzeMedicalDocumentRequest request,
  ) => remoteDataSource.analyze(request);

  @override
  Future<MedicalDocumentEntity> getById(String documentId) =>
      remoteDataSource.getById(documentId);

  @override
  Future<List<MedicalDocumentRejectionReasonEntity>> getRejectionReasons() {
    final cached = _rejectionReasons;
    if (cached != null) return Future.value(cached);
    final pending = _rejectionReasonsLoad;
    if (pending != null) return pending;

    late final Future<List<MedicalDocumentRejectionReasonEntity>> request;
    request = remoteDataSource
        .getRejectionReasons()
        .then((reasons) {
          final immutable =
              List<MedicalDocumentRejectionReasonEntity>.unmodifiable(reasons);
          _rejectionReasons = immutable;
          return immutable;
        })
        .whenComplete(() {
          if (identical(_rejectionReasonsLoad, request)) {
            _rejectionReasonsLoad = null;
          }
        });
    _rejectionReasonsLoad = request;
    return request;
  }

  @override
  Future<void> submitAiFeedback(MedicalDocumentAiFeedback feedback) =>
      remoteDataSource.submitAiFeedback(feedback);

  @override
  Future<MedicalDocumentEntity> review(
    String documentId,
    ReviewMedicalDocumentRequest request,
  ) async {
    final document = await remoteDataSource.review(documentId, request);
    if (document.status == MedicalDocumentStatus.accepted) {
      for (final animalId in document.animalIds) {
        _invalidateAnimal(animalId);
      }
    }
    return document;
  }

  @override
  Future<List<MedicalDocumentEntity>> getByAnimal(
    String animalId, {
    MedicalDocumentCategory? category,
    bool forceRefresh = false,
  }) {
    final key = _MedicalDocumentsCacheKey(animalId, category);
    if (!forceRefresh) {
      final cached = _cache[key];
      if (cached != null) return Future.value(cached);

      final pending = _inFlight[key];
      if (pending != null) return pending;
    }

    final generation = forceRefresh
        ? (_cacheGenerations[key] ?? 0) + 1
        : _cacheGenerations[key] ?? 0;
    _cacheGenerations[key] = generation;

    late final Future<List<MedicalDocumentEntity>> request;
    request = remoteDataSource
        .getByAnimal(animalId, category: category)
        .then((documents) {
          final immutableDocuments = List<MedicalDocumentEntity>.unmodifiable(
            documents,
          );
          if (_cacheGenerations[key] == generation) {
            _cache[key] = immutableDocuments;
          }
          return immutableDocuments;
        })
        .whenComplete(() {
          if (identical(_inFlight[key], request)) {
            _inFlight.remove(key);
          }
        });
    _inFlight[key] = request;
    return request;
  }

  @override
  void clearCache() {
    final keys = {..._cache.keys, ..._inFlight.keys};
    for (final key in keys) {
      _cacheGenerations[key] = (_cacheGenerations[key] ?? 0) + 1;
    }
    _cache.clear();
    _inFlight.clear();
    _rejectionReasons = null;
    _rejectionReasonsLoad = null;
  }

  @override
  Future<Uri> getDownloadUri(String documentId) =>
      remoteDataSource.getDownloadUri(documentId);

  void _invalidateAnimal(String animalId) {
    final keys = {
      ..._cache.keys.where((key) => key.animalId == animalId),
      ..._inFlight.keys.where((key) => key.animalId == animalId),
    };
    for (final key in keys) {
      _cacheGenerations[key] = (_cacheGenerations[key] ?? 0) + 1;
      _cache.remove(key);
      _inFlight.remove(key);
    }
  }
}

class _MedicalDocumentsCacheKey {
  final String animalId;
  final MedicalDocumentCategory? category;

  const _MedicalDocumentsCacheKey(this.animalId, this.category);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MedicalDocumentsCacheKey &&
          animalId == other.animalId &&
          category == other.category;

  @override
  int get hashCode => Object.hash(animalId, category);
}
