import 'dart:async';

import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/core/widgets/dropdowns/app_multi_search_dropdown.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_list_control_button.dart';
import 'package:animal_record/features/home/presentation/widgets/my_animals_content.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/medical_document_flow_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/medical_document_flow_state.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_cubit.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_state.dart';
import 'package:animal_record/features/shared_files/presentation/pages/shared_file_upload_screen.dart';
import 'package:animal_record/features/shared_files/presentation/shared_file_upload_feedback.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnimalCubit extends Mock implements AnimalCubit {}

class _MockAuthBloc extends Mock implements AuthBloc {}

class _MockSharedFilesCubit extends Mock implements SharedFilesCubit {}

class _MockMedicalDocumentFlowCubit extends Mock
    implements MedicalDocumentFlowCubit {}

void main() {
  testWidgets(
    'uses the shared animal filter and applies the selection locally',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final animalCubit = _MockAnimalCubit();
      AnimalState animalState = AnimalInitial();
      final animalStates = StreamController<AnimalState>.broadcast();
      addTearDown(animalStates.close);
      when(() => animalCubit.state).thenAnswer((_) => animalState);
      when(() => animalCubit.stream).thenAnswer((_) => animalStates.stream);
      when(() => animalCubit.animals).thenReturn(const [_animal, _maleAnimal]);

      await tester.pumpWidget(
        BlocProvider<AnimalCubit>.value(
          value: animalCubit,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(0.9)),
              child: child!,
            ),
            home: const Scaffold(body: MyAnimalsContent()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AnimalListControlButton).first);
      await tester.pump();

      await tester.tap(find.byKey(const Key('my-animals-filter-button')));
      await tester.pumpAndSettle();
      expect(find.text('Filtros'), findsOneWidget);

      await tester.tap(find.text('Macho'));
      await tester.tap(find.text('Filtrar'));
      await tester.pumpAndSettle();

      animalState = const AnimalsLoaded([_animal, _maleAnimal]);
      animalStates.add(animalState);
      await tester.pumpAndSettle();

      expect(find.text('Umi'), findsNothing);
      expect(find.text('Max'), findsOneWidget);

      await tester.tap(find.byKey(const Key('my-animals-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limpiar filtros'));
      await tester.tap(find.text('Filtrar'));
      await tester.pumpAndSettle();

      expect(find.text('Umi'), findsOneWidget);
      expect(find.text('Max'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'preselects the only active animal when uploading from My animals',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final animalCubit = _MockAnimalCubit();
      when(() => animalCubit.state).thenReturn(AnimalInitial());
      when(() => animalCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => animalCubit.animals).thenReturn(const [_animal]);
      RouteSettings? uploadRouteSettings;

      await tester.pumpWidget(
        BlocProvider<AnimalCubit>.value(
          value: animalCubit,
          child: MaterialApp(
            onGenerateRoute: (settings) {
              if (settings.name == AppRoutes.sharedFileUpload) {
                uploadRouteSettings = settings;
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => const Scaffold(body: Text('Flujo de subida')),
                );
              }
              return null;
            },
            home: const Scaffold(body: MyAnimalsContent()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final actionsMenu = tester.widget<PopupMenuButton<String>>(
        find.byKey(const Key('my-animals-actions-menu')),
      );
      expect(
        (actionsMenu.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.zero,
      );
      actionsMenu.onSelected?.call('subir_documento');
      await tester.pumpAndSettle();

      final arguments = uploadRouteSettings?.arguments as Map<String, dynamic>;
      expect(arguments['manualUpload'], isTrue);
      expect(arguments['preselectedAnimal'], same(_animal));
      expect(find.text('Flujo de subida'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reports a cancelled upload without leaving My animals', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final animalCubit = _MockAnimalCubit();
    when(() => animalCubit.state).thenReturn(AnimalInitial());
    when(() => animalCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => animalCubit.animals).thenReturn(const [_animal]);
    var cancellationReported = false;

    await tester.pumpWidget(
      BlocProvider<AnimalCubit>.value(
        value: animalCubit,
        child: MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.sharedFileUpload) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar carga'),
                  ),
                ),
              );
            }
            return null;
          },
          home: Scaffold(
            body: MyAnimalsContent(
              onUploadCancelled: () => cancellationReported = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final actionsMenu = tester.widget<PopupMenuButton<String>>(
      find.byKey(const Key('my-animals-actions-menu')),
    );
    actionsMenu.onSelected?.call('subir_documento');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar carga'));
    await tester.pumpAndSettle();

    expect(cancellationReported, isTrue);
    expect(find.byKey(const Key('my-animals-actions-menu')), findsOneWidget);
  });

  testWidgets('shows analysis status immediately while uploading', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final animalCubit = _MockAnimalCubit();
    final authBloc = _MockAuthBloc();
    final sharedFilesCubit = _MockSharedFilesCubit();
    final medicalDocumentFlowCubit = _MockMedicalDocumentFlowCubit();
    when(() => animalCubit.state).thenReturn(const AnimalsLoaded([_animal]));
    when(() => animalCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => animalCubit.animals).thenReturn(const [_animal]);
    when(() => authBloc.state).thenReturn(AuthInitial());
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => sharedFilesCubit.state).thenReturn(SharedFilesInitial());
    when(() => sharedFilesCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => sharedFilesCubit.pendingFiles).thenReturn(const []);
    when(() => medicalDocumentFlowCubit.state).thenReturn(
      const MedicalDocumentFlowState(phase: MedicalDocumentFlowPhase.uploading),
    );
    when(
      () => medicalDocumentFlowCubit.stream,
    ).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AnimalCubit>.value(value: animalCubit),
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<SharedFilesCubit>.value(value: sharedFilesCubit),
          BlocProvider<MedicalDocumentFlowCubit>.value(
            value: medicalDocumentFlowCubit,
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  settings: const RouteSettings(
                    arguments: {
                      'manualUpload': true,
                      'preselectedAnimal': _animal,
                    },
                  ),
                  builder: (_) => const SharedFileUploadScreen(),
                ),
              ),
              child: const Text('Abrir subida'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir subida'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final selector = tester.widget<AppDropdown<AnimalEntity>>(
      find.byType(AppDropdown<AnimalEntity>),
    );
    expect(selector.value, same(_animal));
    expect(selector.enabled, isFalse);
    expect(find.byType(AppMultiSearchDropdown<AnimalEntity>), findsNothing);
    final analysisLabel = tester.widget<Text>(find.text(_analysisMessage));
    expect(analysisLabel.style?.color, AppColors.aiViolet);
    expect(analysisLabel.style?.decoration, TextDecoration.none);
    expect(
      tester.widget<CustomButton>(find.byType(CustomButton)).text,
      'Subir archivo',
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(find.text(_analysisMessage), findsOneWidget);
    verifyNever(() => medicalDocumentFlowCubit.pausePolling());

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text(_analysisMessage), findsOneWidget);
    verifyNever(() => medicalDocumentFlowCubit.resumePolling());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'selects and locks the only active animal for an external shared file',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final animalCubit = _MockAnimalCubit();
      final authBloc = _MockAuthBloc();
      final sharedFilesCubit = _MockSharedFilesCubit();
      final medicalDocumentFlowCubit = _MockMedicalDocumentFlowCubit();
      when(() => animalCubit.state).thenReturn(const AnimalsLoaded([_animal]));
      when(() => animalCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => animalCubit.animals).thenReturn(const [_animal]);
      when(() => authBloc.state).thenReturn(AuthInitial());
      when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => sharedFilesCubit.state).thenReturn(SharedFilesInitial());
      when(
        () => sharedFilesCubit.stream,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => sharedFilesCubit.pendingFiles,
      ).thenReturn(const [_externalFile]);
      when(
        () => medicalDocumentFlowCubit.state,
      ).thenReturn(const MedicalDocumentFlowState());
      when(
        () => medicalDocumentFlowCubit.stream,
      ).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AnimalCubit>.value(value: animalCubit),
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<SharedFilesCubit>.value(value: sharedFilesCubit),
            BlocProvider<MedicalDocumentFlowCubit>.value(
              value: medicalDocumentFlowCubit,
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    settings: const RouteSettings(
                      arguments: {'externalShare': true},
                    ),
                    builder: (_) => const SharedFileUploadScreen(),
                  ),
                ),
                child: const Text('Abrir archivo externo'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir archivo externo'));
      await tester.pumpAndSettle();

      final selector = tester.widget<AppDropdown<AnimalEntity>>(
        find.byType(AppDropdown<AnimalEntity>),
      );
      expect(selector.value, same(_animal));
      expect(selector.enabled, isFalse);
      expect(find.byType(AppMultiSearchDropdown<AnimalEntity>), findsNothing);
      expect(
        tester.widget<CustomButton>(find.byType(CustomButton)).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keeps an external analysis open while the notification shade is visible',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final animalCubit = _MockAnimalCubit();
      final authBloc = _MockAuthBloc();
      final sharedFilesCubit = _MockSharedFilesCubit();
      final medicalDocumentFlowCubit = _MockMedicalDocumentFlowCubit();
      const flowState = MedicalDocumentFlowState(
        phase: MedicalDocumentFlowPhase.analyzing,
      );
      when(() => animalCubit.state).thenReturn(const AnimalsLoaded([_animal]));
      when(() => animalCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => animalCubit.animals).thenReturn(const [_animal]);
      when(() => authBloc.state).thenReturn(AuthInitial());
      when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => sharedFilesCubit.state).thenReturn(SharedFilesInitial());
      when(
        () => sharedFilesCubit.stream,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => sharedFilesCubit.pendingFiles,
      ).thenReturn(const [_externalFile]);
      when(() => medicalDocumentFlowCubit.state).thenAnswer((_) => flowState);
      when(
        () => medicalDocumentFlowCubit.stream,
      ).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AnimalCubit>.value(value: animalCubit),
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<SharedFilesCubit>.value(value: sharedFilesCubit),
            BlocProvider<MedicalDocumentFlowCubit>.value(
              value: medicalDocumentFlowCubit,
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    settings: const RouteSettings(
                      arguments: {'externalShare': true},
                    ),
                    builder: (_) => const SharedFileUploadScreen(),
                  ),
                ),
                child: const Text('Abrir archivo externo'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir archivo externo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(find.byType(SharedFileUploadScreen), findsOneWidget);
      expect(find.text(_analysisMessage), findsOneWidget);
      verifyNever(() => medicalDocumentFlowCubit.pausePolling());
      verifyNever(() => sharedFilesCubit.clear());
      verifyNever(() => medicalDocumentFlowCubit.discardCurrentFlow());

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.byType(SharedFileUploadScreen), findsOneWidget);
      expect(find.text(_analysisMessage), findsOneWidget);
      verifyNever(() => medicalDocumentFlowCubit.resumePolling());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'discards and closes an external upload when the app is backgrounded',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final animalCubit = _MockAnimalCubit();
      final authBloc = _MockAuthBloc();
      final sharedFilesCubit = _MockSharedFilesCubit();
      final medicalDocumentFlowCubit = _MockMedicalDocumentFlowCubit();
      when(() => animalCubit.state).thenReturn(const AnimalsLoaded([_animal]));
      when(() => animalCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => animalCubit.animals).thenReturn(const [_animal]);
      when(() => authBloc.state).thenReturn(AuthInitial());
      when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => sharedFilesCubit.state).thenReturn(SharedFilesInitial());
      when(
        () => sharedFilesCubit.stream,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => sharedFilesCubit.pendingFiles,
      ).thenReturn(const [_externalFile]);
      when(() => medicalDocumentFlowCubit.state).thenReturn(
        const MedicalDocumentFlowState(
          phase: MedicalDocumentFlowPhase.analyzing,
        ),
      );
      when(
        () => medicalDocumentFlowCubit.stream,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => medicalDocumentFlowCubit.discardCurrentFlow(),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AnimalCubit>.value(value: animalCubit),
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<SharedFilesCubit>.value(value: sharedFilesCubit),
            BlocProvider<MedicalDocumentFlowCubit>.value(
              value: medicalDocumentFlowCubit,
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Column(
                children: [
                  const Text('Inicio normal'),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(
                          arguments: {'externalShare': true},
                        ),
                        builder: (_) => const SharedFileUploadScreen(),
                      ),
                    ),
                    child: const Text('Abrir archivo externo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir archivo externo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Subir archivo'), findsWidgets);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Inicio normal'), findsOneWidget);
      expect(find.byType(SharedFileUploadScreen), findsNothing);
      expect(find.text(sharedFileAnalysisInterruptedMessage), findsOneWidget);
      verify(() => sharedFilesCubit.clear()).called(1);
      verify(() => medicalDocumentFlowCubit.discardCurrentFlow()).called(1);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets(
    'discards an internal analysis and reports why when the app resumes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final animalCubit = _MockAnimalCubit();
      final authBloc = _MockAuthBloc();
      final sharedFilesCubit = _MockSharedFilesCubit();
      final medicalDocumentFlowCubit = _MockMedicalDocumentFlowCubit();
      when(() => animalCubit.state).thenReturn(const AnimalsLoaded([_animal]));
      when(() => animalCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => animalCubit.animals).thenReturn(const [_animal]);
      when(() => authBloc.state).thenReturn(AuthInitial());
      when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => sharedFilesCubit.state).thenReturn(SharedFilesInitial());
      when(
        () => sharedFilesCubit.stream,
      ).thenAnswer((_) => const Stream.empty());
      when(() => sharedFilesCubit.pendingFiles).thenReturn(const []);
      when(() => medicalDocumentFlowCubit.state).thenReturn(
        const MedicalDocumentFlowState(
          phase: MedicalDocumentFlowPhase.uploading,
        ),
      );
      when(
        () => medicalDocumentFlowCubit.stream,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => medicalDocumentFlowCubit.discardCurrentFlow(),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AnimalCubit>.value(value: animalCubit),
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<SharedFilesCubit>.value(value: sharedFilesCubit),
            BlocProvider<MedicalDocumentFlowCubit>.value(
              value: medicalDocumentFlowCubit,
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Column(
                children: [
                  const Text('Inicio normal'),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(
                          arguments: {
                            'manualUpload': true,
                            'preselectedAnimal': _animal,
                          },
                        ),
                        builder: (_) => const SharedFileUploadScreen(),
                      ),
                    ),
                    child: const Text('Abrir subida'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir subida'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(_analysisMessage), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(find.byType(SharedFileUploadScreen), findsOneWidget);
      verify(() => medicalDocumentFlowCubit.discardCurrentFlow()).called(1);
      verifyNever(() => sharedFilesCubit.clear());

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Inicio normal'), findsOneWidget);
      expect(find.byType(SharedFileUploadScreen), findsNothing);
      expect(find.text(sharedFileAnalysisInterruptedMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 4));
    },
  );
}

const _analysisMessage =
    'La IA está analizando tu archivo\n'
    'Por favor, no salgas de la pantalla.';

const _animal = AnimalEntity(
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

const _maleAnimal = AnimalEntity(
  id: 'animal-2',
  name: 'Max',
  code: 'AR-C001',
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

const _externalFile = SharedFileEntity(
  path: '/shared/document.pdf',
  name: 'document.pdf',
  mimeType: 'application/pdf',
  type: SharedFileType.pdf,
);
