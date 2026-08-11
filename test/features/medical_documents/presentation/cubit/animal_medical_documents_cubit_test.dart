import 'dart:async';

import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetAnimalMedicalDocumentsUseCase extends Mock
    implements GetAnimalMedicalDocumentsUseCase {}

void main() {
  const animalId = 'animal-1';
  const category = MedicalDocumentCategory.vaccinationCard;

  test(
    'preserves the first document when a second upload is refreshed',
    () async {
      final getDocuments = _MockGetAnimalMedicalDocumentsUseCase();
      final cubit = AnimalMedicalDocumentsCubit(
        getDocumentsUseCase: getDocuments,
      );
      addTearDown(cubit.close);

      when(
        () => getDocuments(animalId, category: category),
      ).thenAnswer((_) async => [_document('first')]);
      await cubit.load(animalId, category: category);

      when(
        () => getDocuments(animalId, category: category),
      ).thenAnswer((_) async => [_document('second')]);
      await cubit.refreshAfterUpload(animalId, category: category);

      final state = cubit.state as AnimalMedicalDocumentsLoaded;
      expect(state.documents.map((document) => document.id), [
        'second',
        'first',
      ]);
    },
  );

  test('updates an existing document without duplicating it', () async {
    final getDocuments = _MockGetAnimalMedicalDocumentsUseCase();
    final cubit = AnimalMedicalDocumentsCubit(
      getDocumentsUseCase: getDocuments,
    );
    addTearDown(cubit.close);

    when(
      () => getDocuments(animalId, category: category),
    ).thenAnswer((_) async => [_document('same', version: 1)]);
    await cubit.load(animalId, category: category);

    when(
      () => getDocuments(animalId, category: category),
    ).thenAnswer((_) async => [_document('same', version: 2)]);
    await cubit.refreshAfterUpload(animalId, category: category);

    final state = cubit.state as AnimalMedicalDocumentsLoaded;
    expect(state.documents, hasLength(1));
    expect(state.documents.single.version, 2);
  });

  test('does not emit when a pending load completes after close', () async {
    final getDocuments = _MockGetAnimalMedicalDocumentsUseCase();
    final pendingDocuments = Completer<List<MedicalDocumentEntity>>();
    final cubit = AnimalMedicalDocumentsCubit(
      getDocumentsUseCase: getDocuments,
    );

    when(
      () => getDocuments(animalId, category: category),
    ).thenAnswer((_) => pendingDocuments.future);

    final load = cubit.load(animalId, category: category);
    await cubit.close();
    pendingDocuments.complete([_document('late-document')]);

    await expectLater(load, completes);
  });
}

MedicalDocumentEntity _document(String id, {int version = 1}) {
  return MedicalDocumentEntity(
    id: id,
    animalIds: const ['animal-1'],
    originalFileName: '$id.pdf',
    mimeType: 'application/pdf',
    fileSize: 100,
    status: MedicalDocumentStatus.accepted,
    finalCategory: MedicalDocumentCategory.vaccinationCard,
    validatedExtraction: const MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.vaccinationCard,
      vaccinations: [
        MedicalDocumentItemEntity(id: 'rabies', fields: {'name': 'Rabia'}),
      ],
    ),
    version: version,
  );
}
