import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/widgets/media/image_preview_dialog.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_cubit.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_state.dart';
import 'package:animal_record/features/diary/presentation/pages/animal_diary_screen.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDiaryCubit extends Mock implements DiaryCubit {}

void main() {
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
