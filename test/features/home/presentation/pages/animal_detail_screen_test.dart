import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/pages/animal_detail_screen.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_family_icon_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  testWidgets('opens the reusable empty pages for diagnostic records', (
    tester,
  ) async {
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
            AppRoutes.animalDiagnosticImages: (context) => Scaffold(
              body: Column(
                children: [
                  const Text('Listado de imágenes diagnósticas'),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar listado'),
                  ),
                ],
              ),
            ),
            AppRoutes.animalLaboratoryResults: (_) =>
                const Scaffold(body: Text('Listado de resultados')),
          },
          home: AnimalDetailScreen(
            animal: _animal,
            hasMedicalDocuments: (_, _) async => false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final diagnosticImages = find.text('Imágenes diagnósticas');
    await tester.ensureVisible(diagnosticImages);
    await tester.tap(diagnosticImages);
    await tester.pumpAndSettle();

    expect(find.text('Actualmente no tiene archivos subidos'), findsOneWidget);
    expect(
      find.text(
        'Recopila todas las imágenes\n'
        'diagnósticas importantes del animal.',
      ),
      findsOneWidget,
    );
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Cancelar'), findsNothing);
    expect(
      find.byKey(const Key('close-animal-empty-feature')),
      findsOneWidget,
    );
    final familyIconBox = find.byType(AnimalFamilyIconBox);
    expect(familyIconBox, findsOneWidget);
    expect(
      find.descendant(of: familyIconBox, matching: find.byType(SvgPicture)),
      findsOneWidget,
    );

    final contentRect = tester.getRect(
      find.byKey(const Key('animal-empty-feature-content')),
    );
    final titleRect = tester.getRect(find.text('Imágenes diagnósticas').last);
    final buttonRect = tester.getRect(
      find.ancestor(
        of: find.text('Continuar'),
        matching: find.byType(ElevatedButton),
      ),
    );
    final topGap = contentRect.top - titleRect.bottom;
    final bottomGap = buttonRect.top - contentRect.bottom;
    expect((topGap - bottomGap).abs(), lessThanOrEqualTo(8));

    final placeholder = tester.widget<Container>(
      find.byKey(const Key('animal-empty-feature-placeholder')),
    );
    final copy = tester.widget<ConstrainedBox>(
      find.byKey(const Key('animal-empty-feature-copy')),
    );
    final contentGap = tester.widget<SizedBox>(
      find.byKey(const Key('animal-empty-feature-content-gap')),
    );
    final textGap = tester.widget<SizedBox>(
      find.byKey(const Key('animal-empty-feature-text-gap')),
    );
    final mainText = tester.widget<Text>(
      find.text('Actualmente no tiene archivos subidos'),
    );
    final subText = tester.widget<Text>(
      find.text(
        'Recopila todas las imágenes\n'
        'diagnósticas importantes del animal.',
      ),
    );

    expect(placeholder.constraints?.maxWidth, 200);
    expect(copy.constraints.maxWidth, 360);
    expect(copy.constraints.maxWidth, isNot(placeholder.constraints?.maxWidth));
    expect(contentGap.height, 48);
    expect(textGap.height, 16);
    expect(mainText.style?.fontSize, AppTypography.body3.fontSize);
    expect(subText.style?.fontSize, AppTypography.body4.fontSize);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Listado de imágenes diagnósticas'), findsOneWidget);
    await tester.tap(find.text('Cerrar listado'));
    await tester.pumpAndSettle();

    final labResults = find.text('Resultados de laboratorio');
    await tester.ensureVisible(labResults);
    await tester.tap(labResults);
    await tester.pumpAndSettle();

    expect(find.text('Actualmente no tiene registros'), findsOneWidget);
    expect(
      find.text(
        'Aquí podrá encontrar todos los resultados de laboratorio que se '
        'suban del animal.',
      ),
      findsOneWidget,
    );
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Cancelar'), findsNothing);
    expect(
      find.byKey(const Key('close-animal-empty-feature')),
      findsOneWidget,
    );

    final labContentRect = tester.getRect(
      find.byKey(const Key('animal-empty-feature-content')),
    );
    final labTitleRect = tester.getRect(
      find.text('Resultados de laboratorio').last,
    );
    final labButtonRect = tester.getRect(
      find.ancestor(
        of: find.text('Continuar'),
        matching: find.byType(ElevatedButton),
      ),
    );
    final labTopGap = labContentRect.top - labTitleRect.bottom;
    final labBottomGap = labButtonRect.top - labContentRect.bottom;
    expect((labTopGap - labBottomGap).abs(), lessThanOrEqualTo(8));

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Listado de resultados'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens saved diagnostic and laboratory records directly', (
    tester,
  ) async {
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
            AppRoutes.animalDiagnosticImages: (_) =>
                const Scaffold(body: Text('Listado diagnóstico guardado')),
            AppRoutes.animalLaboratoryResults: (_) =>
                const Scaffold(body: Text('Listado laboratorio guardado')),
          },
          home: AnimalDetailScreen(
            animal: _animal,
            hasMedicalDocuments: (_, _) async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final diagnosticImages = find.text('Imágenes diagnósticas');
    await tester.ensureVisible(diagnosticImages);
    await tester.tap(diagnosticImages);
    await tester.pumpAndSettle();

    expect(find.text('Listado diagnóstico guardado'), findsOneWidget);
    expect(find.text('Actualmente no tiene archivos subidos'), findsNothing);

    Navigator.of(
      tester.element(find.text('Listado diagnóstico guardado')),
    ).pop();
    await tester.pumpAndSettle();

    final laboratoryResults = find.text('Resultados de laboratorio');
    await tester.ensureVisible(laboratoryResults);
    await tester.tap(laboratoryResults);
    await tester.pumpAndSettle();

    expect(find.text('Listado laboratorio guardado'), findsOneWidget);
    expect(find.text('Actualmente no tiene registros'), findsNothing);
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
