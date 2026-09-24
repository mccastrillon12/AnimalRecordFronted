import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/theme/app_shadows.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/pages/animal_file_records_screen.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/animal_medical_documents_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnimalMedicalDocumentsCubit extends Mock
    implements AnimalMedicalDocumentsCubit {}

class _MockAnimalCubit extends Mock implements AnimalCubit {}

void main() {
  testWidgets('shows the diagnostic images records layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpRecordsScreen(
      tester,
      section: AnimalFileRecordSection.diagnosticImages,
    );

    expect(find.text('Imágenes diagnósticas'), findsOneWidget);
    expect(find.text('No hay archivos subidos'), findsOneWidget);
    expect(
      find.text(
        'Aquí se podrán visualizar las imágenes\n'
        'diagnósticas que se suban.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('animal-file-records-search-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('animal-file-records-sort-button')),
      findsOneWidget,
    );
    final sortButton = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(const Key('animal-file-records-sort-button')),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((sortButton.decoration! as BoxDecoration).boxShadow, const [
      AppShadows.card,
    ]);
    expect(
      find.byKey(const Key('animal-document-upload-menu')),
      findsOneWidget,
    );
    final uploadMenu = tester.widget<PopupMenuButton<String>>(
      find.byKey(const Key('animal-document-upload-menu')),
    );
    expect(
      (uploadMenu.shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.zero,
    );
  });

  testWidgets('shows the laboratory results records layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpRecordsScreen(
      tester,
      section: AnimalFileRecordSection.laboratoryResults,
    );

    expect(find.text('Resultados de laboratorio'), findsOneWidget);
    expect(
      find.text('El registro de resultados de laboratorio está vacío'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Aquí se podrán visualizar los resultados\n'
        'de laboratorio que se suban.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('animal-document-upload-menu')),
      findsOneWidget,
    );
  });

  testWidgets('uses the formulas card layout for a laboratory result', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const document = MedicalDocumentEntity(
      id: '8c268acf-1111-2222-3333-444444444444',
      documentCode: 'LAB-001',
      animalIds: ['animal-1'],
      originalFileName: 'historia clinica 2.png',
      mimeType: 'image/png',
      fileSize: 100,
      status: MedicalDocumentStatus.accepted,
      finalCategory: MedicalDocumentCategory.laboratoryResult,
      validatedExtraction: MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.laboratoryResult,
        documentDate: '04/08/2026',
      ),
      version: 1,
    );
    const historyDocument = MedicalDocumentEntity(
      id: 'history-document',
      animalIds: ['animal-1'],
      originalFileName: 'historia que no debe mostrarse.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.accepted,
      finalCategory: MedicalDocumentCategory.clinicalHistory,
      validatedExtraction: MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.clinicalHistory,
      ),
      version: 1,
    );

    await _pumpRecordsScreen(
      tester,
      section: AnimalFileRecordSection.laboratoryResults,
      documents: const [document, historyDocument],
    );

    expect(
      find.text('Adjunto: Resultados de laboratorio N° LAB-001'),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key(
          'medical-document-card-icon-8c268acf-1111-2222-3333-444444444444',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Fecha:'), findsOneWidget);
    expect(find.text('04/08/2026'), findsOneWidget);
    expect(find.text('Archivo:'), findsOneWidget);
    expect(find.text('historia clinica 2.png'), findsOneWidget);
    expect(find.text('historia que no debe mostrarse.pdf'), findsNothing);
    expect(find.text('Ver detalle'), findsOneWidget);
    final listGap = tester.widget<SizedBox>(
      find.byKey(const Key('animal-file-records-list-gap')),
    );
    expect(listGap.height, 24);
  });

  testWidgets('shows diagnostic images as 140 by 100 thumbnails', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const document = MedicalDocumentEntity(
      id: 'diagnostic-image-1',
      documentCode: 'I-57-01',
      animalIds: ['animal-1'],
      originalFileName: 'radiografia-lateral.png',
      mimeType: 'image/png',
      fileSize: 100,
      status: MedicalDocumentStatus.accepted,
      finalCategory: MedicalDocumentCategory.diagnosticImage,
      validatedExtraction: MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.diagnosticImage,
        diagnosticImages: [
          MedicalDocumentItemEntity(
            id: 'image-1',
            fields: {'name': 'Radiografía lateral'},
          ),
        ],
      ),
      version: 2,
    );

    await _pumpRecordsScreen(
      tester,
      section: AnimalFileRecordSection.diagnosticImages,
      documents: const [document],
      diagnosticThumbnailUriLoader: (_) async =>
          Uri.parse('https://example.test/radiografia-lateral.png'),
    );

    final thumbnail = tester.widget<Container>(
      find.byKey(const Key('diagnostic-image-thumbnail-diagnostic-image-1')),
    );
    expect(thumbnail.constraints?.maxWidth, 140);
    expect(thumbnail.constraints?.maxHeight, 100);
    expect(find.text('radiografia-lateral.png'), findsOneWidget);
    expect(find.textContaining('Adjunto:'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(
          const Key('diagnostic-image-thumbnail-diagnostic-image-1'),
        ),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps diagnostic thumbnails when sorting and reopening', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const documents = [
      MedicalDocumentEntity(
        id: 'diagnostic-cache-a',
        animalIds: ['animal-1'],
        originalFileName: 'zeta.png',
        mimeType: 'image/png',
        fileSize: 100,
        status: MedicalDocumentStatus.accepted,
        finalCategory: MedicalDocumentCategory.diagnosticImage,
        validatedExtraction: MedicalDocumentExtractionEntity(
          documentType: MedicalDocumentCategory.diagnosticImage,
        ),
        version: 1,
      ),
      MedicalDocumentEntity(
        id: 'diagnostic-cache-b',
        animalIds: ['animal-1'],
        originalFileName: 'alfa.png',
        mimeType: 'image/png',
        fileSize: 100,
        status: MedicalDocumentStatus.accepted,
        finalCategory: MedicalDocumentCategory.diagnosticImage,
        validatedExtraction: MedicalDocumentExtractionEntity(
          documentType: MedicalDocumentCategory.diagnosticImage,
        ),
        version: 1,
      ),
    ];
    final loads = <String, int>{};
    Future<Uri> loadThumbnail(String documentId) async {
      loads.update(documentId, (count) => count + 1, ifAbsent: () => 1);
      return Uri.parse('https://example.test/$documentId.png');
    }

    await _pumpRecordsScreen(
      tester,
      section: AnimalFileRecordSection.diagnosticImages,
      documents: documents,
      diagnosticThumbnailUriLoader: loadThumbnail,
    );
    expect(loads, {'diagnostic-cache-a': 1, 'diagnostic-cache-b': 1});

    await tester.tap(find.byKey(const Key('animal-file-records-sort-button')));
    await tester.pump();

    expect(loads, {'diagnostic-cache-a': 1, 'diagnostic-cache-b': 1});
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await _pumpRecordsScreen(
      tester,
      section: AnimalFileRecordSection.diagnosticImages,
      documents: documents,
      diagnosticThumbnailUriLoader: loadThumbnail,
      settle: false,
    );

    expect(loads, {'diagnostic-cache-a': 1, 'diagnostic-cache-b': 1});
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('reuses the existing animal document upload flow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final animalCubit = _MockAnimalCubit();
    final documentsCubit = _MockAnimalMedicalDocumentsCubit();
    when(() => animalCubit.animals).thenReturn(const [_animalEntity]);
    when(() => animalCubit.state).thenReturn(AnimalInitial());
    when(() => animalCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => documentsCubit.state).thenReturn(
      const AnimalMedicalDocumentsLoaded(
        [],
        category: MedicalDocumentCategory.diagnosticImage,
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
          home: const AnimalFileRecordsScreen(
            animal: _animal,
            section: AnimalFileRecordSection.diagnosticImages,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('animal-document-upload-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subir archivos'));
    await tester.pumpAndSettle();

    expect(find.text('Flujo de subida existente'), findsOneWidget);
    expect(uploadRouteSettings?.name, AppRoutes.sharedFileUpload);
    final arguments = uploadRouteSettings?.arguments as Map<String, dynamic>;
    expect(arguments['manualUpload'], isTrue);
    expect(arguments['preselectedAnimal'], same(_animalEntity));
    expect(
      arguments['requestedCategory'],
      MedicalDocumentCategory.diagnosticImage,
    );
  });
}

Future<void> _pumpRecordsScreen(
  WidgetTester tester, {
  required AnimalFileRecordSection section,
  List<MedicalDocumentEntity> documents = const [],
  MedicalDocumentThumbnailUriLoader? diagnosticThumbnailUriLoader,
  bool settle = true,
}) async {
  final documentsCubit = _MockAnimalMedicalDocumentsCubit();
  final category = switch (section) {
    AnimalFileRecordSection.diagnosticImages =>
      MedicalDocumentCategory.diagnosticImage,
    AnimalFileRecordSection.laboratoryResults =>
      MedicalDocumentCategory.laboratoryResult,
  };
  when(
    () => documentsCubit.state,
  ).thenReturn(AnimalMedicalDocumentsLoaded(documents, category: category));
  when(() => documentsCubit.stream).thenAnswer((_) => const Stream.empty());

  await tester.pumpWidget(
    BlocProvider<AnimalMedicalDocumentsCubit>.value(
      value: documentsCubit,
      child: MaterialApp(
        home: AnimalFileRecordsScreen(
          animal: _animal,
          section: section,
          diagnosticThumbnailUriLoader: diagnosticThumbnailUriLoader,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
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
