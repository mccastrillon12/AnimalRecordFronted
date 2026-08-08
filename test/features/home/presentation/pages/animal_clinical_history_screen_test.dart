import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/pages/animal_clinical_history_screen.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAnimalCubit extends Mock implements AnimalCubit {}

class MockAnimalMedicalDocumentsCubit extends Mock
    implements AnimalMedicalDocumentsCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const animal = AnimalModel(
    id: 'animal-1',
    name: 'Brownie',
    code: 'AR-C012',
    family: 'Canino',
  );
  const animalEntity = AnimalEntity(
    id: 'animal-1',
    name: 'Brownie',
    code: 'AR-C012',
    species: 'DOG',
    breed: 'Labrador',
    sex: 'MALE',
    reproductiveStatus: 'INTACT',
    hasChip: false,
    isAssociationMember: false,
    temperament: [],
    diagnosis: [],
    ownerId: 'owner-1',
  );

  testWidgets('renders the clinical history empty state for the animal', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final documentsCubit = MockAnimalMedicalDocumentsCubit();
    when(() => documentsCubit.state).thenReturn(
      const AnimalMedicalDocumentsLoaded(
        [],
        category: MedicalDocumentCategory.clinicalHistory,
      ),
    );
    when(() => documentsCubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      BlocProvider<AnimalMedicalDocumentsCubit>.value(
        value: documentsCubit,
        child: const MaterialApp(
          home: AnimalClinicalHistoryScreen(animal: animal),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Historia clínica'), findsOneWidget);
    expect(find.textContaining('Brownie', findRichText: true), findsOneWidget);
    expect(find.textContaining('AR-C012', findRichText: true), findsOneWidget);
    expect(
      find.text(
        'Aquí podrá visualizar los veterinarios que han atendido al animal '
        'y han creado historias clínicas en Animal Record.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('clinical-history-search-field')),
      findsOneWidget,
    );
    final searchField = tester.widget<TextField>(
      find.byKey(const Key('clinical-history-search-field')),
    );
    final enabledBorder = searchField.decoration?.enabledBorder;
    expect(enabledBorder, isA<OutlineInputBorder>());
    expect(
      (enabledBorder! as OutlineInputBorder).borderSide,
      const BorderSide(color: AppColors.greyDelineante, width: 1),
    );
    final headerDescriptionGap = tester.widget<SizedBox>(
      find.byKey(const Key('clinical-history-header-description-gap')),
    );
    final descriptionSearchGap = tester.widget<SizedBox>(
      find.byKey(const Key('clinical-history-description-search-gap')),
    );
    expect(headerDescriptionGap.height, 32);
    expect(descriptionSearchGap.height, 32);
    expect(
      find.text('El registro de historias clínicas está vacío'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Aquí se podrán visualizar las historias clínicas que se creen.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('animal-document-upload-menu')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the existing upload flow with the animal preselected', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final animalCubit = MockAnimalCubit();
    final documentsCubit = MockAnimalMedicalDocumentsCubit();
    when(() => animalCubit.animals).thenReturn(const [animalEntity]);
    when(() => animalCubit.state).thenReturn(AnimalInitial());
    when(() => animalCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => documentsCubit.state).thenReturn(
      const AnimalMedicalDocumentsLoaded(
        [],
        category: MedicalDocumentCategory.clinicalHistory,
      ),
    );
    when(() => documentsCubit.stream).thenAnswer((_) => const Stream.empty());
    RouteSettings? uploadRouteSettings;

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AnimalCubit>.value(value: animalCubit),
          BlocProvider<AnimalMedicalDocumentsCubit>.value(
            value: documentsCubit,
          ),
        ],
        child: MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.sharedFileUpload) {
              uploadRouteSettings = settings;
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) =>
                    const Scaffold(body: Text('Flujo de subida existente')),
              );
            }
            return null;
          },
          home: const AnimalClinicalHistoryScreen(animal: animal),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('animal-document-upload-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Subir documentos'), findsOneWidget);

    await tester.tap(find.text('Subir documentos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Historia clínica'), findsOneWidget);
    expect(find.text('Flujo de subida existente'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('Flujo de subida existente'), findsOneWidget);
    expect(uploadRouteSettings?.name, AppRoutes.sharedFileUpload);
    final arguments = uploadRouteSettings?.arguments as Map<String, dynamic>;
    expect(arguments['manualUpload'], isTrue);
    expect(arguments['preselectedAnimal'], same(animalEntity));
    expect(
      arguments['requestedCategory'],
      MedicalDocumentCategory.clinicalHistory,
    );
    expect(tester.takeException(), isNull);
  });
}
