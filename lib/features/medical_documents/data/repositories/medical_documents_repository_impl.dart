import 'package:animal_record/features/medical_documents/data/datasources/medical_documents_remote_datasource.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:animal_record/features/medical_documents/domain/repositories/medical_documents_repository.dart';

class MedicalDocumentsRepositoryImpl implements MedicalDocumentsRepository {
  final MedicalDocumentsRemoteDataSource remoteDataSource;

  const MedicalDocumentsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<MedicalDocumentEntity> analyze(
    AnalyzeMedicalDocumentRequest request,
  ) => remoteDataSource.analyze(request);

  @override
  Future<MedicalDocumentEntity> getById(String documentId) =>
      remoteDataSource.getById(documentId);

  @override
  Future<MedicalDocumentEntity> review(
    String documentId,
    ReviewMedicalDocumentRequest request,
  ) => remoteDataSource.review(documentId, request);

  @override
  Future<List<MedicalDocumentEntity>> getByAnimal(
    String animalId, {
    MedicalDocumentCategory? category,
  }) => remoteDataSource.getByAnimal(animalId, category: category);

  @override
  Future<Uri> getDownloadUri(String documentId) =>
      remoteDataSource.getDownloadUri(documentId);
}
