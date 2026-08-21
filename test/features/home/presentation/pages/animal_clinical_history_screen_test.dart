import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/features/auth/domain/entities/user_entity.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
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

class MockAuthBloc extends Mock implements AuthBloc {}

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

    final authBloc = MockAuthBloc();
    final documentsCubit = MockAnimalMedicalDocumentsCubit();
    final accountOwner = UserEntity.empty().copyWith(name: 'Barbara James');
    when(() => authBloc.state).thenReturn(AuthSuccess(accountOwner));
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => documentsCubit.state).thenReturn(
      const AnimalMedicalDocumentsLoaded(
        [],
        category: MedicalDocumentCategory.clinicalHistory,
      ),
    );
    when(() => documentsCubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<AnimalMedicalDocumentsCubit>.value(
            value: documentsCubit,
          ),
        ],
        child: const MaterialApp(
          home: AnimalClinicalHistoryScreen(animal: animal),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Historias clínicas'), findsOneWidget);
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
    expect(searchField.enabled, isFalse);
    expect(searchField.decoration?.fillColor, AppColors.white);
    final enabledBorder = searchField.decoration?.enabledBorder;
    final disabledBorder = searchField.decoration?.disabledBorder;
    expect(enabledBorder, isA<OutlineInputBorder>());
    expect(
      (enabledBorder! as OutlineInputBorder).borderSide,
      const BorderSide(color: AppColors.greyBordes, width: 1),
    );
    expect(
      (disabledBorder! as OutlineInputBorder).borderSide,
      const BorderSide(color: AppColors.greyBordes, width: 1),
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
    expect(find.text('Subir archivos'), findsOneWidget);

    await tester.tap(find.text('Subir archivos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Historias clínicas'), findsOneWidget);
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

  testWidgets('groups clinical histories and opens the selected group', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final authBloc = MockAuthBloc();
    final documentsCubit = MockAnimalMedicalDocumentsCubit();
    final accountOwner = UserEntity.empty().copyWith(name: 'Barbara James');
    when(() => authBloc.state).thenReturn(AuthSuccess(accountOwner));
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    const extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.clinicalHistory,
      documentDate: 'January 25, 2026',
      issuer: {'name': 'Marc Doe', 'clinic': 'Clínica Punto Vet'},
    );
    const documents = [
      MedicalDocumentEntity(
        id: 'history-1',
        animalIds: ['animal-1'],
        originalFileName: 'history-1.pdf',
        mimeType: 'application/pdf',
        fileSize: 100,
        status: MedicalDocumentStatus.accepted,
        finalCategory: MedicalDocumentCategory.clinicalHistory,
        validatedExtraction: extraction,
        version: 1,
      ),
      MedicalDocumentEntity(
        id: 'history-2',
        animalIds: ['animal-1'],
        originalFileName: 'history-2.pdf',
        mimeType: 'application/pdf',
        fileSize: 100,
        status: MedicalDocumentStatus.accepted,
        finalCategory: MedicalDocumentCategory.clinicalHistory,
        validatedExtraction: extraction,
        version: 1,
      ),
    ];
    when(() => documentsCubit.state).thenReturn(
      const AnimalMedicalDocumentsLoaded(
        documents,
        category: MedicalDocumentCategory.clinicalHistory,
      ),
    );
    when(() => documentsCubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<AnimalMedicalDocumentsCubit>.value(
            value: documentsCubit,
          ),
        ],
        child: const MaterialApp(
          home: AnimalClinicalHistoryScreen(animal: animal),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Barbara James'), findsOneWidget);
    expect(find.text('Marc Doe'), findsNothing);
    expect(find.text('Archivos:'), findsOneWidget);
    final documentCountBadge = find.byKey(
      const Key('clinical-history-document-count-Barbara James'),
    );
    expect(documentCountBadge, findsOneWidget);
    expect(
      find.descendant(of: documentCountBadge, matching: find.text('2')),
      findsOneWidget,
    );
    expect(find.text('2'), findsNWidgets(2));

    final search = find.byKey(const Key('clinical-history-search-field'));
    expect(tester.widget<TextField>(search).enabled, isTrue);
    await tester.enterText(search, '1234567890123456789012345');
    await tester.pump();
    expect(
      tester.widget<TextField>(search).controller?.text,
      '12345678901234567890',
    );

    await tester.enterText(search, 'history-2.pdf');
    await tester.pump();
    expect(find.text('Barbara James'), findsOneWidget);

    await tester.enterText(search, 'sin coincidencias');
    await tester.pump();
    expect(find.text('Barbara James'), findsNothing);
    expect(find.text('No se encontraron historias clínicas.'), findsOneWidget);

    await tester.enterText(search, '');
    await tester.pump();

    final groupCard = find.byKey(
      const Key('clinical-history-group-Barbara James'),
    );
    await tester.tapAt(tester.getTopLeft(groupCard) + const Offset(12, 12));
    await tester.pumpAndSettle();

    expect(find.text('Subidas por mí'), findsOneWidget);
    expect(find.text('Historia clínica 1'), findsOneWidget);
    expect(find.text('Historia clínica 2'), findsOneWidget);
    expect(find.text('Descargar todo'), findsOneWidget);
    expect(
      find.byKey(const Key('animal-document-upload-menu')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('clinical-history-menu-history-1')));
    await tester.pumpAndSettle();

    expect(find.text('Descargar historia'), findsOneWidget);
    expect(find.text('Cambiar privacidad'), findsNothing);
  });

  testWidgets('opens the only history detail from its overview card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final authBloc = MockAuthBloc();
    final documentsCubit = MockAnimalMedicalDocumentsCubit();
    final accountOwner = UserEntity.empty().copyWith(name: 'Barbara James');
    when(() => authBloc.state).thenReturn(AuthSuccess(accountOwner));
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => documentsCubit.state).thenReturn(
      const AnimalMedicalDocumentsLoaded([
        MedicalDocumentEntity(
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
            patient: MedicalDocumentPatientEntity(
              name: 'Chuleta',
              identifier: '101077',
              species: 'Canine (Dog)',
              breed: 'Chihuahua',
              reproductiveStatus: 'Neutered',
              fields: {
                'name': 'Chuleta',
                'identifier': '101077',
                'species': 'Canine (Dog)',
                'breed': 'Chihuahua',
                'reproductiveStatus': 'Neutered',
              },
            ),
          ),
          version: 1,
        ),
      ], category: MedicalDocumentCategory.clinicalHistory),
    );
    when(() => documentsCubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<AnimalMedicalDocumentsCubit>.value(
            value: documentsCubit,
          ),
        ],
        child: const MaterialApp(
          home: AnimalClinicalHistoryScreen(animal: animal),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Historias clínicas'), findsOneWidget);
    expect(find.text('Enviar historia clínica'), findsNothing);
    expect(
      find.byKey(const Key('clinical-history-search-field')),
      findsOneWidget,
    );
    expect(find.text('Ver historias'), findsOneWidget);

    final singleHistoryCard = find.byKey(
      const Key('clinical-history-group-Barbara James'),
    );
    await tester.tapAt(
      tester.getTopLeft(singleHistoryCard) + const Offset(12, 12),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enviar historia clínica'), findsOneWidget);
    expect(find.text('Document Date'), findsOneWidget);
    expect(find.text('December 1, 2026'), findsOneWidget);
    expect(find.text('Original File Name'), findsOneWidget);
    expect(find.text('Identifier'), findsOneWidget);
    expect(find.text('101077'), findsOneWidget);
    expect(find.text('Species'), findsOneWidget);
    expect(find.text('Reproductive Status'), findsOneWidget);
    expect(find.text('Neutered'), findsOneWidget);
    expect(
      find.byKey(const Key('clinical-history-search-field')),
      findsNothing,
    );
  });

  testWidgets('shows the current user name, initials and own-group title', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final authBloc = MockAuthBloc();
    final documentsCubit = MockAnimalMedicalDocumentsCubit();
    final user = UserEntity.empty().copyWith(name: 'Maria Perez');
    when(() => authBloc.state).thenReturn(AuthSuccess(user));
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => documentsCubit.state).thenReturn(
      const AnimalMedicalDocumentsLoaded([
        MedicalDocumentEntity(
          id: 'own-history',
          animalIds: ['animal-1'],
          originalFileName: 'own-history.pdf',
          mimeType: 'application/pdf',
          fileSize: 100,
          status: MedicalDocumentStatus.accepted,
          finalCategory: MedicalDocumentCategory.clinicalHistory,
          validatedExtraction: MedicalDocumentExtractionEntity(
            documentType: MedicalDocumentCategory.clinicalHistory,
          ),
          version: 1,
        ),
        MedicalDocumentEntity(
          id: 'own-history-2',
          animalIds: ['animal-1'],
          originalFileName: 'own-history-2.pdf',
          mimeType: 'application/pdf',
          fileSize: 100,
          status: MedicalDocumentStatus.accepted,
          finalCategory: MedicalDocumentCategory.clinicalHistory,
          validatedExtraction: MedicalDocumentExtractionEntity(
            documentType: MedicalDocumentCategory.clinicalHistory,
          ),
          version: 1,
        ),
      ], category: MedicalDocumentCategory.clinicalHistory),
    );
    when(() => documentsCubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<AnimalMedicalDocumentsCubit>.value(
            value: documentsCubit,
          ),
        ],
        child: const MaterialApp(
          home: AnimalClinicalHistoryScreen(animal: animal),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maria Perez'), findsOneWidget);
    expect(find.text('MP'), findsOneWidget);

    await tester.tap(find.text('Ver historias'));
    await tester.pumpAndSettle();

    expect(find.text('Subidas por mí'), findsOneWidget);
  });
}
