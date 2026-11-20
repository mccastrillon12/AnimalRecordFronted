import 'dart:convert';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/widgets/media/image_preview_dialog.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/home/domain/entities/animal_ownership.dart';
import 'package:animal_record/features/home/domain/usecases/animal_history_usecases.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_cubit.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_state.dart';
import 'package:animal_record/features/diary/presentation/pages/animal_diary_create_screen.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDiaryCubit extends Mock implements DiaryCubit {}

class _MockDownloadHistoricalFile extends Mock
    implements DownloadHistoricalFileUseCase {}

void main() {
  testWidgets(
    'consulta adjuntos históricos desde la previsualización sin usar su URL',
    (tester) async {
      final cubit = _MockDiaryCubit();
      final download = _MockDownloadHistoricalFile();
      const reference = HistoricalFileReference(
        periodId: 'period-1',
        publicationHash: 'hash-1',
        entryId: 'entry-1',
        fileId: 'image-1',
      );
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      when(() => download(reference)).thenAnswer((_) async => bytes);
      di.sl.registerSingleton<DownloadHistoricalFileUseCase>(download);
      addTearDown(() => di.sl.unregister<DownloadHistoricalFileUseCase>());
      when(() => cubit.state).thenReturn(DiaryInitial());
      when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        BlocProvider<DiaryCubit>.value(
          value: cubit,
          child: const MaterialApp(
            home: AnimalDiaryCreateScreen(
              animal: AnimalModel(
                id: 'animal-1',
                name: 'Luna',
                code: 'AR-001',
                family: 'Canino',
                transferStatus: 'TRANSFERRED',
              ),
              readOnly: true,
              entry: DiaryEntryEntity(
                id: 'entry-1',
                animalId: 'animal-1',
                title: 'Control',
                content: 'Consulta histórica.',
                date: '2026-11-18',
                attachments: [
                  DiaryAttachmentEntity(
                    id: 'image-1',
                    fileName: 'foto.png',
                    fileType: 'image',
                    mimeType: 'image/png',
                    url: 'https://example.test/unused.png',
                    historicalFile: reference,
                    size: 68,
                    createdAt: '2026-11-18T10:00:00Z',
                  ),
                ],
                createdAt: '2026-11-18T10:00:00Z',
                updatedAt: '2026-11-18T10:00:00Z',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      verifyNever(() => download(reference));
      expect(find.text('Guardar'), findsNothing);
      expect(find.byType(IconButton), findsOneWidget);
      await tester.ensureVisible(find.text('foto.png'));
      await tester.tap(find.text('foto.png'));
      await tester.pumpAndSettle();
      final image = tester.widget<ImagePreviewDialog>(
        find.byType(ImagePreviewDialog),
      );
      expect(image.imageBytes, bytes);
      expect(image.imageUrl, isEmpty);
      verify(() => download(reference)).called(1);
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.byType(ImagePreviewDialog), findsNothing);
      expect(find.byType(AnimalDiaryCreateScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('hides the keyboard when tapping outside the diary fields', (
    tester,
  ) async {
    final cubit = _MockDiaryCubit();
    when(() => cubit.state).thenReturn(DiaryInitial());
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      BlocProvider<DiaryCubit>.value(
        value: cubit,
        child: const MaterialApp(
          home: AnimalDiaryCreateScreen(
            animal: AnimalModel(
              id: 'animal-1',
              name: 'Luna',
              code: 'AR-001',
              family: 'Canino',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('diary-content-field')));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.text('Título'));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);
  });
}
