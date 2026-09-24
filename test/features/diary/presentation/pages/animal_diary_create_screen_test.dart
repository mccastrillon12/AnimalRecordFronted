import 'package:animal_record/features/diary/presentation/cubit/diary_cubit.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_state.dart';
import 'package:animal_record/features/diary/presentation/pages/animal_diary_create_screen.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDiaryCubit extends Mock implements DiaryCubit {}

void main() {
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
