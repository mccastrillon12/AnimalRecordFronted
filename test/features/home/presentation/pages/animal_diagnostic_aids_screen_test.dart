import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_shadows.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/pages/animal_diagnostic_aids_screen.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_file_saver.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  testWidgets('renders other documents from left to right using Grupo 844', (
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
    final newestIcon = tester.widget<SvgPicture>(
      find.byKey(const Key('diagnostic-aid-folder-icon-document-4')),
    );
    expect(newestIcon.width, 75);
    expect(newestIcon.height, 64);
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

  testWidgets('opens a folder with its document and no upload menu', (
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
    await tester.pumpAndSettle();

    expect(find.text('Carpeta 1'), findsOneWidget);
    expect(find.text('Ayuda diagnóstica 1'), findsOneWidget);
    expect(find.text('Agosto 4, 2026'), findsOneWidget);
    expect(
      find.byKey(const Key('diagnostic-aid-document-document-1')),
      findsOneWidget,
    );
    final icon = tester.widget<SvgPicture>(
      find.byKey(const Key('diagnostic-aid-document-icon-document-1')),
    );
    expect(icon.width, 30);
    expect(icon.height, 30);
    final documentCardRect = tester.getRect(
      find.byKey(const Key('diagnostic-aid-document-document-1')),
    );
    expect(documentCardRect.left, 24);
    expect(documentCardRect.right, 390 - 24);
    final shadowBox = tester.widget<DecoratedBox>(
      find.byKey(const Key('diagnostic-aid-document-shadow-document-1')),
    );
    final shadowDecoration = shadowBox.decoration as BoxDecoration;
    expect(shadowDecoration.boxShadow, const [AppShadows.card]);
    expect(find.byKey(const Key('animal-document-upload-menu')), findsNothing);

    await tester.tap(
      find.byKey(const Key('diagnostic-aid-document-menu-document-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Descargar archivo'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('download-diagnostic-aid-document-1')),
    );
    await tester.pumpAndSettle();

    verify(() => downloadUriUseCase('document-1')).called(1);
    final saveRequest =
        verify(() => saveOriginalUseCase(captureAny())).captured.single
            as MedicalDocumentFileSaveRequest;
    expect(saveRequest.fileName, 'diagnostico-1.pdf');
    expect(saveRequest.remoteUri, originalUri);
  });
}

MedicalDocumentEntity _document({
  required String id,
  required String fileName,
  required DateTime updatedAt,
}) {
  return MedicalDocumentEntity(
    id: id,
    animalIds: const ['animal-1'],
    originalFileName: fileName,
    mimeType: 'application/pdf',
    fileSize: 100,
    status: MedicalDocumentStatus.accepted,
    finalCategory: MedicalDocumentCategory.other,
    version: 1,
    updatedAt: updatedAt,
  );
}
