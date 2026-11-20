import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/widgets/media/image_preview_dialog.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_cubit.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_state.dart';
import 'package:animal_record/features/diary/presentation/pages/animal_diary_screen.dart';
import 'package:animal_record/features/diary/presentation/pages/animal_diary_create_screen.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_family_icon_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mocktail/mocktail.dart';

class MockDiaryCubit extends Mock implements DiaryCubit {}

void main() {
  for (final status in ['PENDING', 'TRANSFERRED']) {
    testWidgets(
      'una tarjeta $status abre el formulario existente en solo lectura sin recargar el diario',
      (tester) async {
        final cubit = MockDiaryCubit();
        final content = List.generate(
          20,
          (i) => 'Información de la nota, línea $i.',
        ).join('\n');
        final entry = DiaryEntryEntity(
          id: 'entry-1',
          animalId: 'animal-1',
          title: 'Nota histórica',
          content: content,
          date: '2026-11-18',
          attachments: const [],
          createdAt: '2026-11-18T10:00:00Z',
          updatedAt: '2026-11-18T10:00:00Z',
        );
        when(() => cubit.state).thenReturn(DiaryLoaded([entry]));
        when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
        when(
          () => cubit.getDiaryEntries(
            'animal-1',
            historical: status == 'TRANSFERRED',
            readOnly: true,
          ),
        ).thenAnswer((_) async {});
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          BlocProvider<DiaryCubit>.value(
            value: cubit,
            child: MaterialApp(
              home: AnimalDiaryScreen(
                animal: AnimalModel(
                  id: 'animal-1',
                  name: 'Luna',
                  code: 'AR-E018',
                  family: 'Equino',
                  transferStatus: status,
                  readOnly: status == 'TRANSFERRED',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(find.text(content)).maxLines, 4);
        await tester.tap(find.text('Nota histórica'));
        await tester.pumpAndSettle();
        final preview = tester.widget<AnimalDiaryCreateScreen>(
          find.byType(AnimalDiaryCreateScreen),
        );
        expect(preview.entry, entry);
        expect(preview.readOnly, isTrue);
        expect(
          find.byType(AnimalDiaryScreen, skipOffstage: false),
          findsOneWidget,
        );
        for (final fieldKey in ['diary-title-field', 'diary-content-field']) {
          final fieldFinder = find.byKey(Key(fieldKey));
          final field = tester.widget<TextField>(fieldFinder);
          expect(field.readOnly, isTrue);
          expect(
            field.controller!.text,
            fieldKey == 'diary-title-field' ? entry.title : content,
          );
          await tester.tap(fieldFinder);
          await tester.pump();
          expect(tester.testTextInput.isVisible, isFalse);
        }
        expect(find.text('Miércoles, 18 de noviembre'), findsOneWidget);
        expect(find.text('Guardar'), findsNothing);
        expect(find.text('+ Nueva nota'), findsNothing);
        expect(find.text('Cancelar'), findsNothing);
        await tester.tap(
          find.descendant(
            of: find.byType(AnimalDiaryCreateScreen),
            matching: find.byIcon(Icons.close),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<AnimalDiaryScreen>(find.byType(AnimalDiaryScreen))
              .readOnlyEntry,
          isNull,
        );
        verify(
          () => cubit.getDiaryEntries(
            'animal-1',
            historical: status == 'TRANSFERRED',
            readOnly: true,
          ),
        ).called(1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final status in [null, 'PROCESSING']) {
    testWidgets('conserva la navegación del diario para el estado $status', (
      tester,
    ) async {
      final cubit = MockDiaryCubit();
      const entry = DiaryEntryEntity(
        id: 'entry-1',
        animalId: 'animal-1',
        title: 'Nota de control',
        content: 'Resultado de la consulta.',
        date: '2026-11-18',
        attachments: [],
        createdAt: '2026-11-18T10:00:00Z',
        updatedAt: '2026-11-18T10:00:00Z',
      );
      when(() => cubit.state).thenReturn(DiaryLoaded([entry]));
      when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
      when(
        () =>
            cubit.getDiaryEntries('animal-1', readOnly: status == 'PROCESSING'),
      ).thenAnswer((_) async {});
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        BlocProvider<DiaryCubit>.value(
          value: cubit,
          child: MaterialApp(
            home: AnimalDiaryScreen(
              animal: AnimalModel(
                id: 'animal-1',
                name: 'Luna',
                code: 'AR-001',
                family: 'Canino',
                transferStatus: status,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.title));
      await tester.pumpAndSettle();
      expect(find.byType(AnimalDiaryCreateScreen), findsNothing);
      if (status == 'PROCESSING') {
        expect(
          tester
              .widget<AnimalDiaryScreen>(find.byType(AnimalDiaryScreen))
              .readOnlyEntry,
          entry,
        );
      } else {
        expect(
          find.byType(AnimalDiaryScreen, skipOffstage: false),
          findsOneWidget,
        );
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Editar'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<AnimalDiaryCreateScreen>(
                find.byType(AnimalDiaryCreateScreen),
              )
              .readOnly,
          isFalse,
        );
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('diary-title-field')))
              .readOnly,
          isFalse,
        );
        expect(find.text('Guardar'), findsOneWidget);
        when(
          () => cubit.updateDiaryEntry(
            animalId: 'animal-1',
            entryId: entry.id,
            title: 'Nota actualizada',
            content: entry.content,
            newAttachments: const [],
            deletedAttachmentIds: const [],
          ),
        ).thenAnswer((_) async {});
        await tester.enterText(
          find.byKey(const Key('diary-title-field')),
          'Nota actualizada',
        );
        await tester.pump();
        await tester.tap(find.text('Guardar'));
        await tester.pump();
        verify(
          () => cubit.updateDiaryEntry(
            animalId: 'animal-1',
            entryId: entry.id,
            title: 'Nota actualizada',
            content: entry.content,
            newAttachments: const [],
            deletedAttachmentIds: const [],
          ),
        ).called(1);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('always shows the family icon in the empty diary state', (
    tester,
  ) async {
    final cubit = MockDiaryCubit();
    when(() => cubit.state).thenReturn(DiaryLoaded(const []));
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.getDiaryEntries(any())).thenAnswer((_) async {});

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      BlocProvider<DiaryCubit>.value(
        value: cubit,
        child: const MaterialApp(
          home: AnimalDiaryScreen(
            animal: AnimalModel(
              id: 'animal-1',
              name: 'Luna',
              code: 'AR-001',
              family: 'Canino',
              imageUrl: 'https://example.test/animal-photo.png',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final familyIconBox = find.byType(AnimalFamilyIconBox);
    expect(familyIconBox, findsOneWidget);
    expect(
      find.descendant(of: familyIconBox, matching: find.byType(SvgPicture)),
      findsOneWidget,
    );

    final contentRect = tester.getRect(
      find.byKey(const Key('diary-empty-content')),
    );
    final titleRect = tester.getRect(find.text('Diario'));
    final buttonRect = tester.getRect(
      find.ancestor(
        of: find.text('+ Nueva nota'),
        matching: find.byType(ElevatedButton),
      ),
    );
    final topGap = contentRect.top - titleRect.bottom;
    final bottomGap = buttonRect.top - contentRect.bottom;
    expect((topGap - bottomGap).abs(), lessThanOrEqualTo(8));
  });

  testWidgets('aligns the image preview close icon with the diary close icon', (
    tester,
  ) async {
    final cubit = MockDiaryCubit();
    final entry = DiaryEntryEntity(
      id: 'entry-1',
      animalId: 'animal-1',
      title: 'Control veterinario',
      content: 'Resultado de la consulta.',
      date: '2026-08-17',
      attachments: const [
        DiaryAttachmentEntity(
          id: 'attachment-1',
          fileName: 'historia-clinica.png',
          fileType: 'image',
          mimeType: 'image/png',
          url: 'https://example.test/historia-clinica.png',
          size: 100,
          createdAt: '2026-08-17T12:00:00Z',
        ),
      ],
      createdAt: '2026-08-17T12:00:00Z',
      updatedAt: '2026-08-17T12:00:00Z',
    );
    when(() => cubit.state).thenReturn(DiaryLoaded([entry]));
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.getDiaryEntries(any())).thenAnswer((_) async {});

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      BlocProvider<DiaryCubit>.value(
        value: cubit,
        child: const MaterialApp(
          home: AnimalDiaryScreen(
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

    final diaryCloseRect = tester.getRect(find.byIcon(Icons.close));
    await tester.tap(find.text('historia-clinica.png'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ImagePreviewDialog), findsOneWidget);
    expect(tester.getRect(find.byTooltip('Cerrar')), diaryCloseRect);
    final barriers = tester.widgetList<ModalBarrier>(find.byType(ModalBarrier));
    expect(
      barriers.any((barrier) => barrier.color == AppColors.overlayBlack),
      isTrue,
    );
  });
}
