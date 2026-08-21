import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/pages/animal_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnimalCubit extends Mock implements AnimalCubit {}

void main() {
  testWidgets('always opens the clinical histories overview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final animalCubit = _MockAnimalCubit();
    when(
      () => animalCubit.state,
    ).thenReturn(const AnimalsLoaded([_animalEntity]));
    when(() => animalCubit.stream).thenAnswer((_) => const Stream.empty());
    await tester.pumpWidget(
      BlocProvider<AnimalCubit>.value(
        value: animalCubit,
        child: MaterialApp(
          routes: {
            AppRoutes.animalClinicalHistory: (_) =>
                const Scaffold(body: Text('Ventana de historias clínicas')),
          },
          home: const AnimalDetailScreen(animal: _animal),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ayudas diagnósticas'), findsNothing);

    final historyItem = find.byKey(
      const Key('animal-clinical-history-menu-item'),
    );
    await tester.ensureVisible(historyItem);
    await tester.tap(historyItem);
    await tester.pumpAndSettle();

    expect(find.text('Ventana de historias clínicas'), findsOneWidget);
    expect(find.text('Enviar historia clínica'), findsNothing);
  });
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
