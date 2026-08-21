import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/core/widgets/dropdowns/app_multi_search_dropdown.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/home/presentation/widgets/my_animals_content.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/medical_document_flow_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/medical_document_flow_state.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_cubit.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_state.dart';
import 'package:animal_record/features/shared_files/presentation/pages/shared_file_upload_screen.dart';
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
      actionsMenu.onSelected?.call('subir_documento');
      await tester.pumpAndSettle();

      final arguments = uploadRouteSettings?.arguments as Map<String, dynamic>;
      expect(arguments['manualUpload'], isTrue);
      expect(arguments['preselectedAnimal'], same(_animal));
      expect(find.text('Flujo de subida'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows the disabled single selector and analysis status', (
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
      const MedicalDocumentFlowState(phase: MedicalDocumentFlowPhase.analyzing),
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
    final analysisLabel = tester.widget<Text>(
      find.text('Analizando archivo...'),
    );
    expect(analysisLabel.style?.color, AppColors.aiViolet);
    expect(analysisLabel.style?.decoration, TextDecoration.none);
    expect(tester.takeException(), isNull);
  });
}

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
