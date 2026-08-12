import 'dart:async';

import 'package:animal_record/features/medical_documents/data/datasources/medical_documents_remote_datasource.dart';
import 'package:animal_record/features/medical_documents/data/models/medical_document_model.dart';
import 'package:animal_record/features/medical_documents/data/repositories/medical_documents_repository_impl.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMedicalDocumentsRemoteDataSource extends Mock
    implements MedicalDocumentsRemoteDataSource {}

void main() {
  const animalId = 'animal-1';
  const category = MedicalDocumentCategory.vaccinationCard;

  late _MockMedicalDocumentsRemoteDataSource remoteDataSource;
  late MedicalDocumentsRepositoryImpl repository;

  setUp(() {
    remoteDataSource = _MockMedicalDocumentsRemoteDataSource();
    repository = MedicalDocumentsRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
  });

  test('reuses vaccination documents stored for the animal', () async {
    when(
      () => remoteDataSource.getByAnimal(animalId, category: category),
    ).thenAnswer((_) async => [_document('cached')]);

    final first = await repository.getByAnimal(animalId, category: category);
    final second = await repository.getByAnimal(animalId, category: category);

    expect(first.single.id, 'cached');
    expect(second.single.id, 'cached');
    verify(
      () => remoteDataSource.getByAnimal(animalId, category: category),
    ).called(1);
  });

  test(
    'coalesces simultaneous loads for the same animal and category',
    () async {
      final pending = Completer<List<MedicalDocumentModel>>();
      when(
        () => remoteDataSource.getByAnimal(animalId, category: category),
      ).thenAnswer((_) => pending.future);

      final first = repository.getByAnimal(animalId, category: category);
      final second = repository.getByAnimal(animalId, category: category);
      pending.complete([_document('shared')]);

      expect((await first).single.id, 'shared');
      expect((await second).single.id, 'shared');
      verify(
        () => remoteDataSource.getByAnimal(animalId, category: category),
      ).called(1);
    },
  );

  test('force refresh obtains and stores the updated documents', () async {
    when(
      () => remoteDataSource.getByAnimal(animalId, category: category),
    ).thenAnswer((_) async => [_document('first')]);
    await repository.getByAnimal(animalId, category: category);

    when(
      () => remoteDataSource.getByAnimal(animalId, category: category),
    ).thenAnswer((_) async => [_document('updated')]);
    final refreshed = await repository.getByAnimal(
      animalId,
      category: category,
      forceRefresh: true,
    );
    final cached = await repository.getByAnimal(animalId, category: category);

    expect(refreshed.single.id, 'updated');
    expect(cached.single.id, 'updated');
    verify(
      () => remoteDataSource.getByAnimal(animalId, category: category),
    ).called(2);
  });

  test('an accepted document update invalidates the animal cache', () async {
    when(
      () => remoteDataSource.getByAnimal(animalId, category: category),
    ).thenAnswer((_) async => [_document('before')]);
    await repository.getByAnimal(animalId, category: category);

    final reviewRequest = ReviewMedicalDocumentRequest.reject(
      documentVersion: 1,
    );
    when(
      () => remoteDataSource.review('document-id', reviewRequest),
    ).thenAnswer((_) async => _document('reviewed'));
    await repository.review('document-id', reviewRequest);

    when(
      () => remoteDataSource.getByAnimal(animalId, category: category),
    ).thenAnswer((_) async => [_document('after')]);
    final documents = await repository.getByAnimal(
      animalId,
      category: category,
    );

    expect(documents.single.id, 'after');
    verify(
      () => remoteDataSource.getByAnimal(animalId, category: category),
    ).called(2);
  });
}

MedicalDocumentModel _document(String id) {
  return MedicalDocumentModel(
    id: id,
    animalIds: const ['animal-1'],
    originalFileName: '$id.pdf',
    mimeType: 'application/pdf',
    fileSize: 100,
    status: MedicalDocumentStatus.accepted,
    finalCategory: MedicalDocumentCategory.vaccinationCard,
    validatedExtraction: const MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.vaccinationCard,
    ),
    version: 1,
  );
}
