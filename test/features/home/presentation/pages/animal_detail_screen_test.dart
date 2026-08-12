import 'dart:async';

import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/pages/animal_detail_screen.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnimalCubit extends Mock implements AnimalCubit {}

void main() {
  testWidgets(
    'shows history loading in the menu and then opens the only detail',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final animalCubit = _MockAnimalCubit();
      when(
        () => animalCubit.state,
      ).thenReturn(const AnimalsLoaded([_animalEntity]));
      when(() => animalCubit.stream).thenAnswer((_) => const Stream.empty());
      final pendingDocuments = Completer<List<MedicalDocumentEntity>>();
      var loaderCalls = 0;

      await tester.pumpWidget(
        BlocProvider<AnimalCubit>.value(
          value: animalCubit,
          child: MaterialApp(
            home: AnimalDetailScreen(
              animal: _animal,
              loadClinicalHistories: (_) {
                loaderCalls++;
                return pendingDocuments.future;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final historyItem = find.byKey(
        const Key('animal-clinical-history-menu-item'),
      );
      await tester.ensureVisible(historyItem);
      await tester.tap(historyItem);
      await tester.pump();

      expect(loaderCalls, 1);
      expect(
        find.byKey(const Key('animal-clinical-history-menu-loading')),
        findsOneWidget,
      );
      expect(find.text('Historias clínicas'), findsNothing);

      pendingDocuments.complete(const [_clinicalHistory]);
      await tester.pumpAndSettle();

      expect(find.text('Enviar historia clínica'), findsOneWidget);
      expect(find.text('Historias clínicas'), findsNothing);
    },
  );
}

const _animal = AnimalModel(
  id: 'animal-1',
  name: 'Umi',
  code: 'AR-F025',
  family: 'Felino',
);

const _animalEntity = AnimalEntity(
  id: 'animal-1',
  name: 'Umi',
  code: 'AR-F025',
  species: 'CAT',
  breed: 'Criollo',
  sex: 'FEMALE',
  reproductiveStatus: 'SPAYED',
  hasChip: false,
  isAssociationMember: false,
  temperament: [],
  diagnosis: [],
  ownerId: 'owner-1',
);

const _clinicalHistory = MedicalDocumentEntity(
  id: 'only-history',
  animalIds: ['animal-1'],
  originalFileName: 'only-history.pdf',
  mimeType: 'application/pdf',
  fileSize: 100,
  status: MedicalDocumentStatus.accepted,
  finalCategory: MedicalDocumentCategory.clinicalHistory,
  validatedExtraction: MedicalDocumentExtractionEntity(
    documentType: MedicalDocumentCategory.clinicalHistory,
    documentDate: 'December 1, 2026',
  ),
  version: 1,
);
