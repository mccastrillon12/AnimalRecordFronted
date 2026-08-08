import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/animal_medical_documents_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnimalMedicalDocumentsCubit extends Mock
    implements AnimalMedicalDocumentsCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders an accepted formula with the compact saved design', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const document = MedicalDocumentEntity(
      id: '7d22ffa7-7927-46bb-b6b1-0f0232243b84',
      animalIds: ['animal-1'],
      originalFileName: 'JAKE 2025-05-15 Formula médica.pdf',
      mimeType: 'application/pdf',
      fileSize: 95861,
      status: MedicalDocumentStatus.accepted,
      finalCategory: MedicalDocumentCategory.prescription,
      validatedExtraction: MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.prescription,
        documentDate: 'miércoles, 14 de mayo de 2025, 7:21 p.m.',
        additionalFields: {'description': 'Control hepático'},
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
    await tester.pumpAndSettle();

    expect(
      find.text('¿La ayuda de la IA te fue útil\npara leer tu documento?'),
      findsOneWidget,
    );
    expect(find.text('Adjunto: Fórmula médica N° 7d22ffa7'), findsOneWidget);
    expect(find.text('Mayo 14, 2025'), findsOneWidget);
    expect(find.text('JAKE 2025-05-15 Formula médica.pdf'), findsOneWidget);
    expect(find.text('Control hepático'), findsOneWidget);
    expect(find.text('Ver detalle'), findsOneWidget);
    expect(
      find.byKey(const Key('medical-document-ai-not-useful')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('medical-document-ai-useful')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
