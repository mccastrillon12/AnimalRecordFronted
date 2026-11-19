import 'package:animal_record/features/home/domain/usecases/animal_history_usecases.dart';
import 'package:animal_record/features/home/data/services/animal_history_cache.dart';
import 'package:animal_record/features/home/domain/entities/animal_ownership.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/medical_documents/domain/repositories/medical_documents_repository.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_file_loader.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/home/data/services/animal_history_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _HistoryRepository extends Mock implements AnimalTransferRepository {}

class _MedicalRepository extends Mock implements MedicalDocumentsRepository {}

class _FileLoader extends Mock implements MedicalDocumentFileLoader {}

class _GetDocuments extends Mock implements GetAnimalMedicalDocumentsUseCase {}

void main() {
  const history = AnimalOwnershipHistory(
    periodId: 'period-1',
    publicationHash: 'hash-1',
    entries: [
      HistoricalEntry(
        entryId: 'entry-1',
        kind: 'MEDICAL_DOCUMENT',
        data: {
          'id': 'doc-1',
          'animalIds': ['animal-1'],
          'originalFileName': 'formula.pdf',
          'mimeType': 'application/pdf',
          'fileSize': 3,
          'status': 'ACCEPTED',
          'finalCategory': 'PRESCRIPTION',
          'version': 2,
          'canReplace': true,
        },
        media: [HistoricalFile('file-1', 'storageKey')],
      ),
    ],
  );
  test(
    'lista documentos en las categorías habituales sin consultar al dueño actual',
    () async {
      final getDocuments = _GetDocuments();
      final cubit = AnimalMedicalDocumentsCubit(
        getDocumentsUseCase: getDocuments,
        historicalDocumentsUseCase: GetHistoricalDocumentsUseCase(
          AnimalHistoryCache(_HistoryRepository()),
        ),
      );
      addTearDown(cubit.close);
      await cubit.load(
        'animal-1',
        history: history,
        category: MedicalDocumentCategory.prescription,
      );
      final document =
          (cubit.state as AnimalMedicalDocumentsLoaded).documents.single;
      expect(document.readOnly, isTrue);
      expect(document.canReplace, isFalse);
      await cubit.load('animal-1', category: MedicalDocumentCategory.referral);
      expect((cubit.state as AnimalMedicalDocumentsLoaded).documents, isEmpty);
      verifyNoMoreInteractions(getDocuments);
    },
  );
  test(
    'descarga bytes de la publicación, sin pedir una URL del expediente vigente',
    () async {
      final medical = _MedicalRepository();
      final loader = _FileLoader();
      final historical = _HistoryRepository();
      when(
        () => historical.downloadHistoricalFile(
          periodId: 'period-1',
          publicationHash: 'hash-1',
          entryId: 'entry-1',
          fileId: 'file-1',
        ),
      ).thenAnswer((_) async => [1, 2, 3]);
      final useCase = LoadMedicalDocumentOriginalUseCase(
        repository: medical,
        fileLoader: loader,
        historicalRepository: historical,
      );
      final file = await useCase(
        AnimalHistorySnapshot.documents(history).single,
      );
      expect(file.bytes, [1, 2, 3]);
      expect(file.name, 'formula.pdf');
      verifyNoMoreInteractions(medical);
      verifyNoMoreInteractions(loader);
      verify(
        () => historical.downloadHistoricalFile(
          periodId: 'period-1',
          publicationHash: 'hash-1',
          entryId: 'entry-1',
          fileId: 'file-1',
        ),
      ).called(1);
    },
  );
}
