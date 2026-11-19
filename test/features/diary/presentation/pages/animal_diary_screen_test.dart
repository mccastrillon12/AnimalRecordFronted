import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/widgets/media/image_preview_dialog.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_cubit.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_state.dart';
import 'package:animal_record/features/diary/presentation/pages/animal_diary_screen.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_family_icon_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mocktail/mocktail.dart';

class MockDiaryCubit extends Mock implements DiaryCubit {}

void main() {
  testWidgets(
    'una tarjeta transferida abre la nota completa sin edición ni otra carga del diario',
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
        () =>
            cubit.getDiaryEntries('animal-1', historical: true, readOnly: true),
      ).thenAnswer((_) async {});
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
                code: 'AR-E018',
                family: 'Equino',
                transferStatus: 'TRANSFERRED',
                readOnly: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text(content)).maxLines, 4);
      await tester.tap(find.text('Nota histórica'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimalDiaryScreen>(find.byType(AnimalDiaryScreen))
            .readOnlyEntry,
        entry,
      );
      expect(tester.widget<Text>(find.text(content)).maxLines, isNull);
      expect(find.byType(EditableText), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(find.text('Guardar'), findsNothing);
      expect(find.text('+ Nueva nota'), findsNothing);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimalDiaryScreen>(find.byType(AnimalDiaryScreen))
            .readOnlyEntry,
        isNull,
      );
      verify(
        () =>
            cubit.getDiaryEntries('animal-1', historical: true, readOnly: true),
      ).called(1);
      expect(tester.takeException(), isNull);
    },
  );

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
