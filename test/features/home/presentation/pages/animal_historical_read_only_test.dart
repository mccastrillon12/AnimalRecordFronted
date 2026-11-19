import 'package:animal_record/features/home/domain/usecases/animal_history_usecases.dart';
import 'package:animal_record/features/home/data/services/animal_history_cache.dart';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/features/home/data/models/animal_data_model.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/pages/animal_detail_screen.dart';
import 'package:animal_record/features/home/presentation/pages/animal_info_screen.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_card.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_info_basic_tab.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_info_additional_tab.dart';
import 'package:animal_record/features/catalogs/presentation/cubit/catalogs_cubit.dart';
import 'package:animal_record/features/catalogs/presentation/cubit/catalogs_state.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements AnimalTransferRepository {}

class _Animals extends Mock implements AnimalCubit {}

class _Catalogs extends Mock implements CatalogsCubit {}

class _Auth extends Mock implements AuthBloc {}

void main() {
  testWidgets(
    'usa la ficha y pestañas habituales con los datos históricos y sin edición',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _Repository();
      di.sl.registerSingleton<AnimalTransferRepository>(repository);
      final historyRepository = AnimalHistoryCache(repository);
      di.sl.registerSingleton(LoadHistoricalAnimalUseCase(historyRepository));
      di.sl.registerSingleton(GetHistoricalDocumentsUseCase(historyRepository));
      addTearDown(() => di.sl.unregister<LoadHistoricalAnimalUseCase>());
      addTearDown(() => di.sl.unregister<GetHistoricalDocumentsUseCase>());
      addTearDown(() => di.sl.unregister<AnimalTransferRepository>());
      final card = AnimalDataModel.fromJson({
        'id': 'animal-1',
        'name': 'Luna',
        'species': 'EQUINE',
        'sex': 'FEMALE',
        'readOnly': true,
        'transferStatus': 'TRANSFERRED',
        'ownershipHistory': {
          'periodId': 'period-1',
          'publicationHash': 'hash-1',
        },
      });
      when(() => repository.getHistory('period-1', 'hash-1')).thenAnswer(
        (_) async => const TransferPage([
          HistoricalEntry(
            entryId: 'animal-entry',
            kind: 'ANIMAL',
            data: {
              'id': 'animal-1',
              'name': 'Luna guardada',
              'species': 'EQUINE',
              'code': 'AR-E018',
              'sex': 'FEMALE',
              'breed': 'Criollo',
              'weight': 340,
              'purpose': 'Reproducción',
            },
            media: [],
          ),
        ], null),
      );
      final animals = _Animals();
      when(() => animals.state).thenReturn(AnimalsLoaded([card]));
      when(() => animals.stream).thenAnswer((_) => const Stream.empty());
      final catalogs = _Catalogs();
      when(() => catalogs.state).thenReturn(CatalogsInitial());
      when(() => catalogs.stream).thenAnswer((_) => const Stream.empty());
      when(() => catalogs.species).thenReturn([]);
      when(() => catalogs.breeds).thenReturn([]);
      when(() => catalogs.adoptionSources).thenReturn([]);
      when(() => catalogs.identificationTypes).thenReturn([]);
      when(() => catalogs.registrationAssociations).thenReturn([]);
      when(() => catalogs.temperaments).thenReturn([]);
      when(() => catalogs.housingTypes).thenReturn([]);
      when(() => catalogs.animalPurposes).thenReturn([]);
      when(() => catalogs.loadSpecies()).thenAnswer((_) async {});
      when(
        () => catalogs.loadAnimalCatalogs(speciesId: any(named: 'speciesId')),
      ).thenAnswer((_) async {});
      final auth = _Auth();
      when(() => auth.state).thenReturn(AuthInitial());
      when(() => auth.stream).thenAnswer((_) => const Stream.empty());
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AnimalCubit>.value(value: animals),
            BlocProvider<CatalogsCubit>.value(value: catalogs),
            BlocProvider<AuthBloc>.value(value: auth),
          ],
          child: MaterialApp(
            routes: {
              '/animal-info': (context) => AnimalInfoScreen(
                animal:
                    ModalRoute.of(context)!.settings.arguments as AnimalModel,
              ),
            },
            home: AnimalDetailScreen(animal: AnimalModel.fromEntity(card)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final hero = tester.widget<AnimalCard>(find.byType(AnimalCard));
      expect(hero.animal.name, 'Luna Guardada');
      expect(hero.animal.weight, 340);
      expect(hero.onEditPhoto, isNull);
      expect(find.text('Transferido'), findsOneWidget);
      expect(
        tester.getBottomLeft(find.text('Transferido')).dy,
        lessThan(tester.getTopLeft(find.byType(AnimalCard)).dy),
      );
      expect(find.text('Solo lectura'), findsNothing);
      expect(find.byType(SelectableText), findsNothing);
      await tester.ensureVisible(find.text('Información'));
      await tester.tap(find.text('Información'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimalInfoBasicTab>(find.byType(AnimalInfoBasicTab))
            .readOnly,
        isTrue,
      );
      expect(find.text('Guardar cambios'), findsNothing);
      await tester.tap(find.widgetWithText(Tab, 'Info. Adicional'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimalInfoAdditionalTab>(
              find.byType(AnimalInfoAdditionalTab),
            )
            .readOnly,
        isTrue,
      );
      await tester.tap(find.widgetWithText(Tab, 'General'));
      await tester.pumpAndSettle();
      expect(find.text('Inactivar historia'), findsNothing);
      verifyNever(() => animals.loadAnimalDetails('animal-1'));
      verify(() => repository.getHistory('period-1', 'hash-1')).called(1);
      verifyNoMoreInteractions(repository);
    },
  );
}
