import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/pages/animal_diagnostic_aids_screen.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_file_saver.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAnimalMedicalDocumentsCubit extends Mock
    implements AnimalMedicalDocumentsCubit {}

class MockGetMedicalDocumentDownloadUriUseCase extends Mock
    implements GetMedicalDocumentDownloadUriUseCase {}

class MockSaveMedicalDocumentOriginalUseCase extends Mock
    implements SaveMedicalDocumentOriginalUseCase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(
    () => registerFallbackValue(
      const MedicalDocumentFileSaveRequest(fileName: 'fallback.pdf'),
    ),
  );

  const animal = AnimalModel(
    id: 'animal-1',
    name: 'Brownie',
    code: 'AR-C012',
    family: 'Canino',
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    AnimalMedicalDocumentsState state,
  ) async {
    final documentsCubit = MockAnimalMedicalDocumentsCubit();
    when(() => documentsCubit.state).thenReturn(state);
    when(() => documentsCubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      BlocProvider<AnimalMedicalDocumentsCubit>.value(
        value: documentsCubit,
        child: const MaterialApp(
          home: AnimalDiagnosticAidsScreen(animal: animal),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the diagnostic aids empty state and shared upload menu', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const AnimalMedicalDocumentsLoaded(
        [],
        category: MedicalDocumentCategory.other,
      ),
    );

    expect(find.text('Ayudas diagnósticas'), findsOneWidget);
    expect(
      find.text('El registro de ayudas diagnósticas está vacío'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Aquí se podrán visualizar las ayudas diagnósticas que se creen.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('animal-document-upload-menu')),
      findsOneWidget,
    );

    final searchField = tester.widget<TextField>(
      find.byKey(const Key('diagnostic-aids-search-field')),
    );
    expect(searchField.enabled, isFalse);
    expect(searchField.decoration?.fillColor, AppColors.white);
  });

  testWidgets('renders PDF previews from left to right', (
    tester,
  ) async {
    final documents = List.generate(
      4,
      (index) => _document(
        id: 'document-${index + 1}',
        fileName: 'diagnostico-${index + 1}.pdf',
        updatedAt: DateTime(2026, 8, index + 1),
      ),
    );
    await pumpScreen(
      tester,
      AnimalMedicalDocumentsLoaded(
        documents,
        category: MedicalDocumentCategory.other,
      ),
    );

    for (var index = 1; index <= 4; index++) {
      expect(
        find.byKey(Key('diagnostic-aid-folder-document-$index')),
        findsOneWidget,
      );
    }
    final newestPreview = find.byKey(
      const Key('diagnostic-aid-file-preview-document-4'),
    );
    expect(newestPreview, findsOneWidget);
    expect(tester.getSize(newestPreview), const Size(75, 64));
    final pdfImage = tester.widget<Image>(
      find.descendant(of: newestPreview, matching: find.byType(Image)),
    );
    expect((pdfImage.image as AssetImage).assetName, 'assets/icons/pdf.png');
    final newestFolderRect = tester.getRect(
      find.byKey(const Key('diagnostic-aid-folder-document-4')),
    );
    final nextFolderRect = tester.getRect(
      find.byKey(const Key('diagnostic-aid-folder-document-3')),
    );
    expect(newestFolderRect.left, lessThan(nextFolderRect.left));
    expect(newestFolderRect.top, nextFolderRect.top);
    expect(
      newestFolderRect.top,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const Key('diagnostic-aid-folder-document-1')),
            )
            .dy,
      ),
    );

    final dropdown = find.byKey(const Key('diagnostic-aids-sort-dropdown'));
    expect(tester.getSize(dropdown), const Size(148, 40));
    expect(
      tester.getSize(find.byKey(const Key('diagnostic-aids-sort-direction'))),
      const Size(40, 40),
    );
    final folderPositionBeforeOpeningDropdown = tester.getTopLeft(
      find.byKey(const Key('diagnostic-aid-folder-document-4')),
    );
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(
        find.byKey(const Key('diagnostic-aid-folder-document-4')),
      ),
      folderPositionBeforeOpeningDropdown,
    );

    await tester.enterText(
      find.byKey(const Key('diagnostic-aids-search-field')),
      'diagnostico-2',
    );
    await tester.pump();

    expect(
      find.byKey(const Key('diagnostic-aid-folder-document-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('diagnostic-aid-folder-document-1')),
      findsNothing,
    );
  });

  testWidgets('renders an image thumbnail for image diagnostic aids', (
    tester,
  ) async {
    await di.sl.reset();
    addTearDown(() => di.sl.reset());
    final downloadUriUseCase = MockGetMedicalDocumentDownloadUriUseCase();
    when(
      () => downloadUriUseCase('image-document'),
    ).thenAnswer((_) async => Uri.parse('https://example.com/diagnostico.png'));
    di.sl.registerSingleton<GetMedicalDocumentDownloadUriUseCase>(
      downloadUriUseCase,
    );

    await pumpScreen(
      tester,
      AnimalMedicalDocumentsLoaded([
        _document(
          id: 'image-document',
          fileName: 'diagnostico.png',
          mimeType: 'image/png',
          updatedAt: DateTime(2026, 8, 4),
        ),
      ], category: MedicalDocumentCategory.other),
    );

    final preview = find.byKey(
      const Key('diagnostic-aid-file-preview-image-document'),
    );
    expect(preview, findsOneWidget);
    final image = tester.widget<CachedNetworkImage>(
      find.descendant(of: preview, matching: find.byType(CachedNetworkImage)),
    );
    expect(image.imageUrl, 'https://example.com/diagnostico.png');
    expect(image.fadeInDuration, Duration.zero);
    expect(image.fadeOutDuration, Duration.zero);
    verify(() => downloadUriUseCase('image-document')).called(1);
  });

  testWidgets('opens the selected diagnostic aid directly', (
    tester,
  ) async {
    await di.sl.reset();
    addTearDown(() => di.sl.reset());
    final downloadUriUseCase = MockGetMedicalDocumentDownloadUriUseCase();
    final saveOriginalUseCase = MockSaveMedicalDocumentOriginalUseCase();
    final originalUri = Uri.parse('https://example.com/diagnostico-1.pdf');
    when(
      () => downloadUriUseCase('document-1'),
    ).thenAnswer((_) async => originalUri);
    when(() => saveOriginalUseCase(any())).thenAnswer((_) async => true);
    di.sl.registerSingleton<GetMedicalDocumentDownloadUriUseCase>(
      downloadUriUseCase,
    );
    di.sl.registerSingleton<SaveMedicalDocumentOriginalUseCase>(
      saveOriginalUseCase,
    );

    final document = _document(
      id: 'document-1',
      fileName: 'diagnostico-1.pdf',
      updatedAt: DateTime(2026, 8, 4),
    );
    await pumpScreen(
      tester,
      AnimalMedicalDocumentsLoaded([
        document,
      ], category: MedicalDocumentCategory.other),
    );

    await tester.tap(find.byKey(const Key('diagnostic-aid-folder-document-1')));
    await tester.pump();

    verify(() => downloadUriUseCase('document-1')).called(1);
    expect(find.text('Carpeta 1'), findsNothing);
  });
}

MedicalDocumentEntity _document({
  required String id,
  required String fileName,
  String mimeType = 'application/pdf',
  required DateTime updatedAt,
}) {
  return MedicalDocumentEntity(
    id: id,
    animalIds: const ['animal-1'],
    originalFileName: fileName,
    mimeType: mimeType,
    fileSize: 100,
    status: MedicalDocumentStatus.accepted,
    finalCategory: MedicalDocumentCategory.other,
    version: 1,
    updatedAt: updatedAt,
  );
}
