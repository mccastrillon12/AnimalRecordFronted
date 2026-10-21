import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_shadows.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_ai_feedback.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/medical_document_detail_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/animal_medical_documents_view.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_card.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:animal_record/features/shared_files/presentation/shared_file_upload_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnimalMedicalDocumentsCubit extends Mock
    implements AnimalMedicalDocumentsCubit {}

class _MockMedicalDocumentDetailCubit extends Mock
    implements MedicalDocumentDetailCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('counts down and hides editing controls when 48 hours expire', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 15, 11);
    final document = MedicalDocumentEntity(
      id: 'countdown-document',
      animalIds: const ['animal-1'],
      originalFileName: 'vacuna.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.accepted,
      finalCategory: MedicalDocumentCategory.vaccinationCard,
      version: 1,
      updatedAt: now.subtract(const Duration(hours: 47)),
      canReplace: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MedicalDocumentEditingControls(
            animalId: 'animal-1',
            document: document,
            category: MedicalDocumentCategory.vaccinationCard,
            instanceKey: 'countdown-document-0',
            now: () => now,
          ),
        ),
      ),
    );

    expect(find.text('Modo edición expira en: 01:00:00'), findsOneWidget);
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Modo edición expira en: 00:59:59'), findsOneWidget);

    now = now.add(const Duration(minutes: 59, seconds: 59));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.byKey(
        const Key('medical-document-editing-controls-countdown-document-0'),
      ),
      findsNothing,
    );
    expect(find.text('Continuar editando'), findsNothing);
    expect(find.text('Eliminar archivo'), findsNothing);
  });

  testWidgets('closes a replacement upload without showing failure feedback', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final document = MedicalDocumentEntity(
      id: 'editable-document',
      animalIds: const ['animal-1'],
      originalFileName: 'vacuna.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.accepted,
      finalCategory: MedicalDocumentCategory.vaccinationCard,
      version: 1,
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      canReplace: true,
    );
    final documentsCubit = _MockAnimalMedicalDocumentsCubit();
    when(() => documentsCubit.state).thenReturn(
      AnimalMedicalDocumentsLoaded([
        document,
      ], category: MedicalDocumentCategory.vaccinationCard),
    );
    when(() => documentsCubit.stream).thenAnswer((_) => const Stream.empty());

    final detailCubit = _MockMedicalDocumentDetailCubit();
    when(
      () => detailCubit.state,
    ).thenReturn(const MedicalDocumentDetailState());
    when(() => detailCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => detailCubit.close()).thenAnswer((_) async {});
    when(
      () => detailCubit.loadRelatedDocuments('editable-document'),
    ).thenAnswer((_) async => [document]);
    when(() => detailCubit.loadOriginalFile(document)).thenAnswer(
      (_) async => const SharedFileEntity(
        path: 'vacuna.pdf',
        name: 'vacuna.pdf',
        mimeType: 'application/pdf',
        type: SharedFileType.pdf,
      ),
    );

    if (di.sl.isRegistered<MedicalDocumentDetailCubit>()) {
      di.sl.unregister<MedicalDocumentDetailCubit>();
    }
    di.sl.registerFactory<MedicalDocumentDetailCubit>(() => detailCubit);
    addTearDown(() async {
      if (di.sl.isRegistered<MedicalDocumentDetailCubit>()) {
        await di.sl.unregister<MedicalDocumentDetailCubit>();
      }
    });

    await tester.pumpWidget(
      BlocProvider<AnimalMedicalDocumentsCubit>.value(
        value: documentsCubit,
        child: MaterialApp(
          routes: {
            AppRoutes.sharedFileUpload: (uploadContext) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(
                    uploadContext,
                    SharedFileUploadCancellation.replacementDismissed,
                  ),
                  child: const Text('Cerrar subida'),
                ),
              ),
            ),
          },
          home: Scaffold(
            body: MedicalDocumentEditingControls(
              animalId: 'animal-1',
              document: document,
              category: MedicalDocumentCategory.vaccinationCard,
              instanceKey: 'silent-cancellation',
              now: DateTime.now,
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const Key('medical-document-continue-editing-silent-cancellation'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Cerrar subida'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('No fue posible subir el documento. Inténtalo nuevamente.'),
      findsNothing,
    );
    verifyNever(
      () => documentsCubit.load(
        'animal-1',
        category: MedicalDocumentCategory.vaccinationCard,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens detail when tapping anywhere on a summary card', (
    tester,
  ) async {
    var detailOpened = false;
    const document = MedicalDocumentEntity(
      id: 'document-tap-target',
      animalIds: ['animal-1'],
      originalFileName: 'formula.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.accepted,
      finalCategory: MedicalDocumentCategory.prescription,
      validatedExtraction: MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.prescription,
      ),
      version: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MedicalDocumentSummaryCard(
            document: document,
            category: MedicalDocumentCategory.prescription,
            onDetail: () => detailOpened = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Adjunto: Fórmula'));

    expect(detailOpened, isTrue);
  });

  testWidgets('renders an accepted formula with the compact saved design', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const document = MedicalDocumentEntity(
      id: '7d22ffa7-7927-46bb-b6b1-0f0232243b84',
      documentCode: 'FORM-007',
      description: 'Control hepático',
      animalIds: ['animal-1'],
      originalFileName: 'JAKE 2025-05-15 Formula médica.pdf',
      mimeType: 'application/pdf',
      fileSize: 95861,
      status: MedicalDocumentStatus.accepted,
      finalCategory: MedicalDocumentCategory.prescription,
      validatedExtraction: MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.prescription,
        documentDate: 'miércoles, 14 de mayo de 2025, 7:21 p.m.',
      ),
      version: 2,
    );
    final cubit = _MockAnimalMedicalDocumentsCubit();
    when(() => cubit.state).thenReturn(
      const AnimalMedicalDocumentsLoaded([
        document,
      ], category: MedicalDocumentCategory.prescription),
    );
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    var feedbackDismissed = false;
    MedicalDocumentAiFeedback? submittedFeedback;

    await tester.pumpWidget(
      BlocProvider<AnimalMedicalDocumentsCubit>.value(
        value: cubit,
        child: MaterialApp(
          home: Scaffold(
            body: AnimalMedicalDocumentsView(
              animalId: 'animal-1',
              category: MedicalDocumentCategory.prescription,
              emptyTitle: 'Sin fórmulas',
              emptyDescription: 'Sin documentos',
              showAiFeedback: true,
              aiFeedbackRequestId: 1,
              onAiFeedbackDismissed: () => feedbackDismissed = true,
              onAiFeedback: (feedback) async => submittedFeedback = feedback,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('¿La ayuda de la IA te fue útil para leer tu archivo?'),
      findsOneWidget,
    );
    expect(find.text('Adjunto: Fórmula N° FORM-007'), findsOneWidget);
    expect(find.text('14/05/2025'), findsOneWidget);
    expect(find.text('JAKE 2025-05-15 Formula médica.pdf'), findsOneWidget);
    expect(find.text('Descripción:'), findsOneWidget);
    expect(find.text('Control hepático'), findsOneWidget);
    expect(find.text('Ver detalle'), findsOneWidget);
    final documentCardFinder = find.byKey(
      const Key('medical-document-card-7d22ffa7-7927-46bb-b6b1-0f0232243b84'),
    );
    expect(tester.widget(documentCardFinder), isA<MedicalDocumentCard>());
    final documentCard = tester.widget<Container>(
      find
          .descendant(of: documentCardFinder, matching: find.byType(Container))
          .first,
    );
    expect((documentCard.decoration! as BoxDecoration).boxShadow, const [
      AppShadows.card,
    ]);
    expect(
      find.byKey(const Key('medical-document-ai-not-useful')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('medical-document-ai-useful')), findsOneWidget);
    void expectWhiteFeedbackButtons() {
      for (final key in const [
        Key('medical-document-ai-not-useful'),
        Key('medical-document-ai-useful'),
      ]) {
        final button = find.byKey(key);
        final material = tester.widget<Material>(
          find.descendant(of: button, matching: find.byType(Material)),
        );
        final ink = tester.widget<Ink>(
          find.descendant(of: button, matching: find.byType(Ink)),
        );
        expect(material.color, AppColors.white);
        expect((ink.decoration! as BoxDecoration).color, AppColors.white);
      }
    }

    expectWhiteFeedbackButtons();
    await tester.tap(find.byKey(const Key('medical-document-ai-useful')));
    await tester.pumpAndSettle();
    expect(submittedFeedback, MedicalDocumentAiFeedback.like);
    expect(
      find.text(
        'Gracias por tu respuesta, la tendremos en cuenta para seguir '
        'entrenando la IA.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('medical-document-ai-feedback-thanks')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('medical-document-ai-not-useful')),
      findsNothing,
    );
    expect(find.byKey(const Key('medical-document-ai-useful')), findsNothing);

    await tester.tap(
      find.byKey(const Key('medical-document-ai-feedback-close')),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('medical-document-ai-feedback-thanks')),
      findsNothing,
    );
    expect(feedbackDismissed, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final dateCase in [
    (
      category: MedicalDocumentCategory.medicalOrder,
      source: '2026-09-24',
      expected: '24/09/2026',
    ),
    (
      category: MedicalDocumentCategory.referral,
      source: '25-09-2025',
      expected: '25/09/2025',
    ),
  ]) {
    testWidgets('formats the ${dateCase.category.label} summary date', (
      tester,
    ) async {
      final document = MedicalDocumentEntity(
        id: 'dated-document',
        animalIds: const ['animal-1'],
        originalFileName: 'documento.pdf',
        mimeType: 'application/pdf',
        fileSize: 100,
        status: MedicalDocumentStatus.accepted,
        finalCategory: dateCase.category,
        validatedExtraction: MedicalDocumentExtractionEntity(
          documentType: dateCase.category,
          documentDate: dateCase.source,
        ),
        version: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MedicalDocumentSummaryCard(
              document: document,
              category: dateCase.category,
            ),
          ),
        ),
      );

      expect(find.text('Fecha:'), findsOneWidget);
      expect(find.text(dateCase.expected), findsOneWidget);
      expect(find.text(dateCase.source), findsNothing);
    });
  }

  testWidgets('shows the thank-you message after negative AI feedback', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const document = MedicalDocumentEntity(
      id: 'document-1',
      animalIds: ['animal-1'],
      originalFileName: 'formula.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.accepted,
      finalCategory: MedicalDocumentCategory.prescription,
      validatedExtraction: MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.prescription,
        additionalFields: {'description': 'No usar en la card'},
      ),
      version: 1,
    );
    final cubit = _MockAnimalMedicalDocumentsCubit();
    when(() => cubit.state).thenReturn(
      const AnimalMedicalDocumentsLoaded([
        document,
      ], category: MedicalDocumentCategory.prescription),
    );
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    MedicalDocumentAiFeedback? submittedFeedback;

    await tester.pumpWidget(
      BlocProvider<AnimalMedicalDocumentsCubit>.value(
        value: cubit,
        child: MaterialApp(
          home: Scaffold(
            body: AnimalMedicalDocumentsView(
              animalId: 'animal-1',
              category: MedicalDocumentCategory.prescription,
              emptyTitle: 'Sin fórmulas',
              emptyDescription: 'Sin documentos',
              showAiFeedback: true,
              aiFeedbackRequestId: 1,
              onAiFeedback: (feedback) async => submittedFeedback = feedback,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('medical-document-ai-not-useful')));
    await tester.pumpAndSettle();

    expect(submittedFeedback, MedicalDocumentAiFeedback.dislike);
    expect(
      find.byKey(const Key('medical-document-ai-feedback-thanks')),
      findsOneWidget,
    );
    expect(find.textContaining('Gracias por tu respuesta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows and submits AI feedback for referrals', (tester) async {
    const document = MedicalDocumentEntity(
      id: 'referral-1',
      animalIds: ['animal-1'],
      originalFileName: 'remision.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.accepted,
      finalCategory: MedicalDocumentCategory.referral,
      validatedExtraction: MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.referral,
        referral: {'destination': 'Cardiología'},
      ),
      version: 1,
    );
    final cubit = _MockAnimalMedicalDocumentsCubit();
    when(() => cubit.state).thenReturn(
      const AnimalMedicalDocumentsLoaded([
        document,
      ], category: MedicalDocumentCategory.referral),
    );
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    MedicalDocumentAiFeedback? submittedFeedback;

    await tester.pumpWidget(
      BlocProvider<AnimalMedicalDocumentsCubit>.value(
        value: cubit,
        child: MaterialApp(
          home: Scaffold(
            body: AnimalMedicalDocumentsView(
              animalId: 'animal-1',
              category: MedicalDocumentCategory.referral,
              emptyTitle: 'Sin remisiones',
              emptyDescription: 'Sin documentos',
              showAiFeedback: true,
              onAiFeedback: (feedback) async => submittedFeedback = feedback,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('¿La ayuda de la IA te fue útil para leer tu archivo?'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('medical-document-ai-not-useful')));
    await tester.pumpAndSettle();

    expect(submittedFeedback, MedicalDocumentAiFeedback.dislike);
    expect(
      find.byKey(const Key('medical-document-ai-feedback-thanks')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows diagnostic images as structured cards while feedback is visible',
    (tester) async {
      const document = MedicalDocumentEntity(
        id: 'diagnostic-image-1',
        animalIds: ['animal-1'],
        originalFileName: 'radiografia.png',
        mimeType: 'image/png',
        fileSize: 100,
        status: MedicalDocumentStatus.accepted,
        finalCategory: MedicalDocumentCategory.diagnosticImage,
        validatedExtraction: MedicalDocumentExtractionEntity(
          documentType: MedicalDocumentCategory.diagnosticImage,
        ),
        version: 1,
      );
      final cubit = _MockAnimalMedicalDocumentsCubit();
      when(() => cubit.state).thenReturn(
        const AnimalMedicalDocumentsLoaded([
          document,
        ], category: MedicalDocumentCategory.diagnosticImage),
      );
      when(() => cubit.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        BlocProvider<AnimalMedicalDocumentsCubit>.value(
          value: cubit,
          child: MaterialApp(
            home: Scaffold(
              body: AnimalMedicalDocumentsView(
                animalId: 'animal-1',
                category: MedicalDocumentCategory.diagnosticImage,
                emptyTitle: 'Sin imágenes',
                emptyDescription: 'Sin documentos',
                showAiFeedback: true,
                onAiFeedback: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('¿La ayuda de la IA te fue útil para leer tu archivo?'),
        findsOneWidget,
      );
      expect(find.byType(MedicalDocumentSummaryCard), findsOneWidget);
      expect(
        find.byKey(const Key('medical-document-card-diagnostic-image-1')),
        findsOneWidget,
      );
      expect(find.text('radiografia.png'), findsOneWidget);
      expect(
        find.byKey(const Key('diagnostic-image-thumbnail-diagnostic-image-1')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shows diagnostic PDFs as structured cards instead of original previews',
    (tester) async {
      const document = MedicalDocumentEntity(
        id: 'diagnostic-pdf-1',
        animalIds: ['animal-1'],
        originalFileName: 'radiografia.pdf',
        mimeType: 'application/pdf',
        fileSize: 100,
        status: MedicalDocumentStatus.accepted,
        finalCategory: MedicalDocumentCategory.diagnosticImage,
        version: 1,
      );
      final cubit = _MockAnimalMedicalDocumentsCubit();
      when(() => cubit.state).thenReturn(
        const AnimalMedicalDocumentsLoaded([
          document,
        ], category: MedicalDocumentCategory.diagnosticImage),
      );
      when(() => cubit.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        BlocProvider<AnimalMedicalDocumentsCubit>.value(
          value: cubit,
          child: MaterialApp(
            home: Scaffold(
              body: AnimalMedicalDocumentsView(
                animalId: 'animal-1',
                category: MedicalDocumentCategory.diagnosticImage,
                emptyTitle: 'Sin imágenes',
                emptyDescription: 'Sin documentos',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MedicalDocumentSummaryCard), findsOneWidget);
      expect(
        find.byKey(const Key('medical-document-card-diagnostic-pdf-1')),
        findsOneWidget,
      );
      expect(find.text('radiografia.pdf'), findsOneWidget);
      expect(
        find.byKey(
          const Key('diagnostic-image-pdf-thumbnail-diagnostic-pdf-1'),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('does not show AI feedback just because documents exist', (
    tester,
  ) async {
    const document = MedicalDocumentEntity(
      id: 'document-1',
      animalIds: ['animal-1'],
      originalFileName: 'formula.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.accepted,
      finalCategory: MedicalDocumentCategory.prescription,
      validatedExtraction: MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.prescription,
      ),
      version: 1,
    );
    final cubit = _MockAnimalMedicalDocumentsCubit();
    when(() => cubit.state).thenReturn(
      const AnimalMedicalDocumentsLoaded([
        document,
      ], category: MedicalDocumentCategory.prescription),
    );
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      BlocProvider<AnimalMedicalDocumentsCubit>.value(
        value: cubit,
        child: const MaterialApp(
          home: Scaffold(
            body: AnimalMedicalDocumentsView(
              animalId: 'animal-1',
              category: MedicalDocumentCategory.prescription,
              emptyTitle: 'Sin fórmulas',
              emptyDescription: 'Sin documentos',
            ),
          ),
        ),
      ),
    );

    expect(
      find.text('¿La ayuda de la IA te fue útil para leer tu archivo?'),
      findsNothing,
    );
    expect(find.text('Ver detalle'), findsOneWidget);
    expect(find.text('Descripción:'), findsNothing);
    expect(find.text('No usar en la card'), findsNothing);
  });

  testWidgets('a new upload request resets the feedback question', (
    tester,
  ) async {
    const document = MedicalDocumentEntity(
      id: 'document-1',
      animalIds: ['animal-1'],
      originalFileName: 'formula.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.accepted,
      finalCategory: MedicalDocumentCategory.prescription,
      validatedExtraction: MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.prescription,
      ),
      version: 1,
    );
    final cubit = _MockAnimalMedicalDocumentsCubit();
    when(() => cubit.state).thenReturn(
      const AnimalMedicalDocumentsLoaded([
        document,
      ], category: MedicalDocumentCategory.prescription),
    );
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());

    Widget view(int requestId) =>
        BlocProvider<AnimalMedicalDocumentsCubit>.value(
          value: cubit,
          child: MaterialApp(
            home: Scaffold(
              body: AnimalMedicalDocumentsView(
                animalId: 'animal-1',
                category: MedicalDocumentCategory.prescription,
                emptyTitle: 'Sin fórmulas',
                emptyDescription: 'Sin documentos',
                showAiFeedback: true,
                aiFeedbackRequestId: requestId,
                onAiFeedback: (_) async {},
              ),
            ),
          ),
        );

    await tester.pumpWidget(view(1));
    await tester.tap(find.byKey(const Key('medical-document-ai-useful')));
    await tester.pump();
    expect(find.textContaining('Gracias por tu respuesta'), findsOneWidget);

    await tester.pumpWidget(view(2));
    await tester.pump();

    expect(
      find.text('¿La ayuda de la IA te fue útil para leer tu archivo?'),
      findsOneWidget,
    );
    expect(find.textContaining('Gracias por tu respuesta'), findsNothing);
  });

  testWidgets('does not show AI feedback when there are no documents', (
    tester,
  ) async {
    final cubit = _MockAnimalMedicalDocumentsCubit();
    when(() => cubit.state).thenReturn(
      const AnimalMedicalDocumentsLoaded(
        [],
        category: MedicalDocumentCategory.prescription,
      ),
    );
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      BlocProvider<AnimalMedicalDocumentsCubit>.value(
        value: cubit,
        child: const MaterialApp(
          home: Scaffold(
            body: AnimalMedicalDocumentsView(
              animalId: 'animal-1',
              category: MedicalDocumentCategory.prescription,
              emptyTitle: 'Sin formulas',
              emptyDescription: 'Sin documentos',
              showAiFeedback: true,
              initialAiFeedbackResponded: true,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('medical-document-ai-feedback-thanks')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('medical-document-ai-not-useful')),
      findsNothing,
    );
    expect(find.byKey(const Key('medical-document-ai-useful')), findsNothing);
  });
}
