import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/home/presentation/pages/animal_documents_screen.dart';
import 'package:animal_record/features/medical_documents/data/datasources/medical_document_ai_feedback_local_datasource.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnimalMedicalDocumentsCubit extends Mock
    implements AnimalMedicalDocumentsCubit {}

class _FakeAiFeedbackStore implements MedicalDocumentAiFeedbackLocalDataSource {
  final Set<(String, MedicalDocumentCategory)> _pending = {};

  @override
  bool isPending(String animalId, MedicalDocumentCategory category) =>
      _pending.contains((animalId, category));

  @override
  Future<void> markPending(
    String animalId,
    MedicalDocumentCategory category,
  ) async {
    _pending.add((animalId, category));
  }

  @override
  Future<void> clearPending(
    String animalId,
    MedicalDocumentCategory category,
  ) async {
    _pending.remove((animalId, category));
  }
}

void main() {
  const animalId = 'animal-1';
  const category = MedicalDocumentCategory.prescription;
  late _FakeAiFeedbackStore feedbackStore;
  late _MockAnimalMedicalDocumentsCubit documentsCubit;

  setUp(() async {
    if (di.sl.isRegistered<MedicalDocumentAiFeedbackLocalDataSource>()) {
      await di.sl.unregister<MedicalDocumentAiFeedbackLocalDataSource>();
    }
    feedbackStore = _FakeAiFeedbackStore();
    di.sl.registerSingleton<MedicalDocumentAiFeedbackLocalDataSource>(
      feedbackStore,
    );

    documentsCubit = _MockAnimalMedicalDocumentsCubit();
    when(
      () => documentsCubit.state,
    ).thenReturn(AnimalMedicalDocumentsLoading());
    when(() => documentsCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() async {
    if (di.sl.isRegistered<MedicalDocumentAiFeedbackLocalDataSource>()) {
      await di.sl.unregister<MedicalDocumentAiFeedbackLocalDataSource>();
    }
  });

  testWidgets(
    'discards unanswered feedback on exit and shows it after a new upload',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await feedbackStore.markPending(animalId, category);

      await _pumpScreen(tester, documentsCubit, key: const ValueKey(1));
      expect(_feedbackGap(tester).height, AppSpacing.m);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(feedbackStore.isPending(animalId, category), isFalse);

      await _pumpScreen(tester, documentsCubit, key: const ValueKey(2));
      expect(_feedbackGap(tester).height, AppSpacing.l);

      await tester.pumpWidget(const SizedBox.shrink());
      await feedbackStore.markPending(animalId, category);
      await _pumpScreen(tester, documentsCubit, key: const ValueKey(3));
      expect(_feedbackGap(tester).height, AppSpacing.m);
    },
  );
}

Future<void> _pumpScreen(
  WidgetTester tester,
  AnimalMedicalDocumentsCubit documentsCubit, {
  required Key key,
}) async {
  await tester.pumpWidget(
    BlocProvider<AnimalMedicalDocumentsCubit>.value(
      value: documentsCubit,
      child: MaterialApp(
        home: AnimalDocumentsScreen(key: key, animalId: 'animal-1'),
      ),
    ),
  );
  await tester.pump();
}

SizedBox _feedbackGap(WidgetTester tester) =>
    tester.widget<SizedBox>(find.byKey(const Key('animal-documents-list-gap')));
