import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/navigation/home_section_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnimalCubit extends Mock implements AnimalCubit {}

void main() {
  testWidgets('opens the vaccination screen directly for a single animal', (
    tester,
  ) async {
    final animalCubit = _MockAnimalCubit();
    when(() => animalCubit.animals).thenReturn(const [_animal]);
    when(() => animalCubit.state).thenReturn(const AnimalsLoaded([_animal]));
    when(() => animalCubit.stream).thenAnswer((_) => const Stream.empty());
    bool? handled;

    await tester.pumpWidget(
      BlocProvider<AnimalCubit>.value(
        value: animalCubit,
        child: MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name != AppRoutes.animalVaccinations) return null;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) {
                final animal = settings.arguments! as AnimalModel;
                return Scaffold(body: Text('vaccinations-${animal.id}'));
              },
            );
          },
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => handled = openSingleAnimalVaccinations(
                context,
                'vaccination_cards',
              ),
              child: const Text('Carné vacunas'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Carné vacunas'));
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text('vaccinations-animal-1'), findsOneWidget);
  });

  testWidgets('keeps the animal selection when more than one animal exists', (
    tester,
  ) async {
    final animalCubit = _MockAnimalCubit();
    when(() => animalCubit.animals).thenReturn(const [
      _animal,
      AnimalEntity(
        id: 'animal-2',
        name: 'Lukas',
        code: 'AR-C002',
        species: 'DOG',
        breed: 'Criollo',
        sex: 'MALE',
        reproductiveStatus: 'INTACT',
        hasChip: false,
        isAssociationMember: false,
        temperament: [],
        diagnosis: [],
        ownerId: 'owner-1',
      ),
    ]);
    when(() => animalCubit.state).thenReturn(const AnimalsLoaded([_animal]));
    when(() => animalCubit.stream).thenAnswer((_) => const Stream.empty());
    bool? handled;

    await tester.pumpWidget(
      BlocProvider<AnimalCubit>.value(
        value: animalCubit,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => handled = openSingleAnimalVaccinations(
                context,
                'vaccination_cards',
              ),
              child: const Text('Carné vacunas'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Carné vacunas'));
    await tester.pump();

    expect(handled, isFalse);
  });
}

const _animal = AnimalEntity(
  id: 'animal-1',
  name: 'Ethan',
  code: 'AR-C037',
  species: 'DOG',
  breed: 'Criollo',
  sex: 'MALE',
  reproductiveStatus: 'INTACT',
  hasChip: false,
  isAssociationMember: false,
  temperament: [],
  diagnosis: [],
  ownerId: 'owner-1',
);
