import 'package:animal_record/features/home/domain/usecases/animal_history_usecases.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/data/services/animal_history_cache.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/home/domain/entities/animal_ownership.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/diary/domain/entities/local_attachment.dart';
import 'package:animal_record/features/diary/domain/usecases/create_diary_entry_usecase.dart';
import 'package:animal_record/features/diary/domain/usecases/delete_attachment_usecase.dart';
import 'package:animal_record/features/diary/domain/usecases/delete_diary_entry_usecase.dart';
import 'package:animal_record/features/diary/domain/usecases/get_diary_entries_usecase.dart';
import 'package:animal_record/features/diary/domain/usecases/update_diary_entry_usecase.dart';
import 'package:animal_record/features/diary/domain/usecases/upload_diary_attachment_usecase.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_cubit.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetDiaryEntriesUseCase extends Mock
    implements GetDiaryEntriesUseCase {}

class MockCreateDiaryEntryUseCase extends Mock
    implements CreateDiaryEntryUseCase {}

class MockUpdateDiaryEntryUseCase extends Mock
    implements UpdateDiaryEntryUseCase {}

class MockDeleteDiaryEntryUseCase extends Mock
    implements DeleteDiaryEntryUseCase {}

class MockDeleteAttachmentUseCase extends Mock
    implements DeleteAttachmentUseCase {}

class MockUploadDiaryAttachmentUseCase extends Mock
    implements UploadDiaryAttachmentUseCase {}

class _HistoryRepository extends Mock implements AnimalTransferRepository {}

void main() {
  late MockGetDiaryEntriesUseCase getDiaryEntriesUseCase;
  late MockCreateDiaryEntryUseCase createDiaryEntryUseCase;
  late MockUploadDiaryAttachmentUseCase uploadDiaryAttachmentUseCase;
  late DiaryCubit cubit;

  const animalId = 'animal-1';
  const entry = DiaryEntryEntity(
    id: 'entry-1',
    animalId: animalId,
    title: 'Control',
    content: 'Contenido',
    date: '2026-07-10',
    attachments: [],
    createdAt: '2026-07-10',
    updatedAt: '2026-07-10',
  );
  const attachment = LocalAttachment(
    path: 'audio.m4a',
    fileName: 'audio.m4a',
    mimeType: 'audio/mp4',
    fileType: 'audio',
    size: 100,
  );

  setUp(() {
    getDiaryEntriesUseCase = MockGetDiaryEntriesUseCase();
    createDiaryEntryUseCase = MockCreateDiaryEntryUseCase();
    uploadDiaryAttachmentUseCase = MockUploadDiaryAttachmentUseCase();
    cubit = DiaryCubit(
      historicalDiaryUseCase: GetHistoricalDiaryUseCase(
        AnimalHistoryCache(_HistoryRepository()),
      ),
      getDiaryEntriesUseCase: getDiaryEntriesUseCase,
      createDiaryEntryUseCase: createDiaryEntryUseCase,
      updateDiaryEntryUseCase: MockUpdateDiaryEntryUseCase(),
      deleteDiaryEntryUseCase: MockDeleteDiaryEntryUseCase(),
      deleteAttachmentUseCase: MockDeleteAttachmentUseCase(),
      uploadDiaryAttachmentUseCase: uploadDiaryAttachmentUseCase,
    );
  });

  tearDown(() => cubit.close());

  test(
    'el diario histórico permite leer y bloquea crear, editar, borrar y cargar',
    () async {
      const history = AnimalOwnershipHistory(
        periodId: 'period-1',
        publicationHash: 'hash-1',
        entries: [
          HistoricalEntry(
            entryId: 'entry-1',
            kind: 'DIARY_ENTRY',
            data: {
              'id': 'entry-1',
              'animalId': animalId,
              'title': 'Control anterior',
              'content': 'Información histórica',
            },
            media: [],
          ),
        ],
      );
      await cubit.getDiaryEntries(
        animalId,
        history: history,
        historical: true,
        readOnly: true,
      );
      expect(cubit.entries.single.content, 'Información histórica');
      await cubit.createDiaryEntry(
        animalId: animalId,
        title: 'Nueva',
        content: 'Cambio',
        date: '2026-11-18',
        attachments: [attachment],
      );
      await cubit.updateDiaryEntry(
        animalId: animalId,
        entryId: 'entry-1',
        title: 'Cambio',
        content: 'Cambio',
      );
      await cubit.deleteDiaryEntry(animalId: animalId, entryId: 'entry-1');
      expect(cubit.entries.single.content, 'Información histórica');
      await cubit.refreshDiaryEntries(animalId);
      expect(cubit.state, isA<DiaryLoaded>());
      verifyNoMoreInteractions(getDiaryEntriesUseCase);
      verifyNoMoreInteractions(createDiaryEntryUseCase);
      verifyNoMoreInteractions(uploadDiaryAttachmentUseCase);
      verifyNoMoreInteractions(cubit.updateDiaryEntryUseCase);
      verifyNoMoreInteractions(cubit.deleteDiaryEntryUseCase);
    },
  );

  void stubEntryCreation() {
    when(
      () => createDiaryEntryUseCase(
        animalId: animalId,
        title: entry.title,
        content: entry.content,
        date: entry.date,
      ),
    ).thenAnswer((_) async => const Right(entry));
  }

  test('mantiene los estados de guardado y éxito con adjuntos', () async {
    stubEntryCreation();
    when(
      () => uploadDiaryAttachmentUseCase(
        animalId: animalId,
        entryId: entry.id,
        attachment: attachment,
      ),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => getDiaryEntriesUseCase(animalId),
    ).thenAnswer((_) async => const Right([entry]));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<DiaryEntrySaving>().having(
          (state) => state.existingEntries,
          'existingEntries',
          isEmpty,
        ),
        isA<DiaryEntrySaved>()
            .having((state) => state.entry, 'entry', entry)
            .having((state) => state.allEntries, 'allEntries', [entry]),
      ]),
    );

    await cubit.createDiaryEntry(
      animalId: animalId,
      title: entry.title,
      content: entry.content,
      date: entry.date,
      attachments: const [attachment],
    );
    await expectation;

    verify(
      () => uploadDiaryAttachmentUseCase(
        animalId: animalId,
        entryId: entry.id,
        attachment: attachment,
      ),
    ).called(1);
  });

  test('detiene el flujo y conserva el mensaje ante error técnico', () async {
    stubEntryCreation();
    when(
      () => uploadDiaryAttachmentUseCase(
        animalId: animalId,
        entryId: entry.id,
        attachment: attachment,
      ),
    ).thenAnswer(
      (_) async =>
          const Left(ServerFailure('Error inesperado: Exception: falló S3')),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<DiaryEntrySaving>(),
        isA<DiaryError>()
            .having(
              (state) => state.message,
              'message',
              'Error inesperado: Exception: falló S3',
            )
            .having(
              (state) => state.existingEntries,
              'existingEntries',
              isEmpty,
            ),
      ]),
    );

    await cubit.createDiaryEntry(
      animalId: animalId,
      title: entry.title,
      content: entry.content,
      date: entry.date,
      attachments: const [attachment],
    );
    await expectation;

    verifyNever(() => getDiaryEntriesUseCase(any()));
  });
}
