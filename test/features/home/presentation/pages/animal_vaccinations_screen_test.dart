import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/pages/animal_vaccinations_screen.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

  testWidgets('renders the empty vaccinations record without cards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final documentsCubit = MockAnimalMedicalDocumentsCubit();
    when(() => documentsCubit.state).thenReturn(
      const AnimalMedicalDocumentsLoaded(
        [],
        category: MedicalDocumentCategory.vaccinationCard,
      ),
    );
    when(() => documentsCubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      BlocProvider<AnimalMedicalDocumentsCubit>.value(
        value: documentsCubit,
        child: const MaterialApp(
          home: AnimalVaccinationsScreen(animal: animal),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ver carné'), findsOneWidget);
    final viewCardCenter = tester.getCenter(
      find.byKey(const Key('view-vaccination-card-button')),
    );
    final closeCenter = tester.getCenter(
      find.byKey(const Key('close-vaccinations-button')),
    );
    expect(viewCardCenter.dy, closeCenter.dy);
    expect(find.text('Carné de vacunas'), findsOneWidget);
    final panelTop = tester.getTopLeft(
      find.byKey(const Key('vaccinations-panel')),
    );
    final titleTop = tester.getTopLeft(
      find.byKey(const Key('vaccinations-title')),
    );
    expect(titleTop.dy - panelTop.dy, 80);
    final title = tester.widget<Text>(
      find.byKey(const Key('vaccinations-title')),
    );
    expect(title.style?.fontSize, 16);
    expect(title.style?.fontWeight, FontWeight.w600);
    expect(title.style?.fontFamily, AppTypography.body1.fontFamily);
    expect(find.text('Verifica que las vacunas estén al día'), findsOneWidget);
    expect(find.textContaining('Brownie', findRichText: true), findsOneWidget);
    expect(find.textContaining('AR-C012', findRichText: true), findsOneWidget);
    final identification = tester.widget<Text>(
      find.byKey(const Key('vaccinations-animal-identification')),
    );
    final identificationSpan = identification.textSpan! as TextSpan;
    final nameSpan = identificationSpan.children!.first as TextSpan;
    expect(nameSpan.style?.fontSize, 14);
    expect(nameSpan.style?.fontWeight, FontWeight.w600);
    expect(identificationSpan.style?.fontSize, 14);
    expect(identificationSpan.style?.fontWeight, FontWeight.w400);
    expect(identification.maxLines, 1);
    expect(find.byKey(const Key('vaccinations-search-field')), findsOneWidget);
    expect(find.byKey(const Key('vaccinations-sort-button')), findsOneWidget);
    final listGap = tester.widget<SizedBox>(
      find.byKey(const Key('vaccinations-list-gap')),
    );
    expect(listGap.height, 24);
    expect(find.text('El registro de vacunas está vacío'), findsOneWidget);
    expect(
      find.text('Aquí se podrán visualizar las vacunas que se creen.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('animal-document-upload-menu')),
      findsOneWidget,
    );
    expect(find.text('Rabia'), findsNothing);
    expect(find.text('Moquillo canino'), findsNothing);
    expect(find.text('Parvovirus'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('groups vaccines without translating backend content', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final documentsCubit = MockAnimalMedicalDocumentsCubit();
    when(() => documentsCubit.state).thenReturn(
      AnimalMedicalDocumentsLoaded([
        _vaccinationDocument(
          id: 'rabies-en',
          vaccinationId: 'rabies-1',
          fields: const {
            'name': 'Rabies',
            'applicationDate': 'June 10, 2024',
            'nextDoseDate': 'June 10, 2025',
          },
        ),
        _vaccinationDocument(
          id: 'rabies-es',
          vaccinationId: 'rabies-2',
          fields: const {
            'name': 'Rabia',
            'applicationDate': '10/27/2025',
            'nextDoseDate': '10/27/2028',
          },
        ),
        _vaccinationDocument(
          id: 'distemper-en',
          vaccinationId: 'distemper-1',
          fields: const {
            'name': 'CANINE DISTEMPER',
            'applicationDate': 'May 1, 2025',
          },
        ),
      ], category: MedicalDocumentCategory.vaccinationCard),
    );
    when(() => documentsCubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      BlocProvider<AnimalMedicalDocumentsCubit>.value(
        value: documentsCubit,
        child: const MaterialApp(
          home: AnimalVaccinationsScreen(animal: animal),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rabia'), findsOneWidget);
    expect(find.text('Canine distemper'), findsOneWidget);
    expect(find.text('CANINE DISTEMPER'), findsNothing);
    expect(find.text('10/27/2025'), findsOneWidget);
    expect(find.text('10/27/2028'), findsOneWidget);
    expect(find.text('Application Date:'), findsNWidgets(2));
    expect(find.text('Next Dose Date:'), findsOneWidget);
    expect(find.byKey(const Key('vaccination-group-rabies')), findsOneWidget);
    expect(
      find.byKey(const Key('vaccination-group-distemper')),
      findsOneWidget,
    );
    final rabiesCard = find.byKey(const Key('vaccination-group-rabies'));
    final distemperCard = find.byKey(const Key('vaccination-group-distemper'));
    expect(
      tester.getTopLeft(rabiesCard).dy,
      lessThan(tester.getTopLeft(distemperCard).dy),
    );

    await tester.tap(find.byKey(const Key('vaccinations-sort-button')));
    await tester.pump();
    expect(
      tester.getTopLeft(distemperCard).dy,
      lessThan(tester.getTopLeft(rabiesCard).dy),
    );

    await tester.enterText(
      find.byKey(const Key('vaccinations-search-field')),
      'Rabies',
    );
    await tester.pump();
    expect(find.text('Rabia'), findsOneWidget);
    expect(find.text('Moquillo canino'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the grouped vaccination detail with every dose', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final documentsCubit = MockAnimalMedicalDocumentsCubit();
    when(() => documentsCubit.state).thenReturn(
      AnimalMedicalDocumentsLoaded([
        _vaccinationDocument(
          id: 'rabies-old',
          vaccinationId: 'rabies-1',
          fields: const {
            'name': 'Rabies',
            'applicationDate': 'June 10, 2024',
            'brand': 'Virbac',
          },
          issuer: const {'name': 'Juanita Doe', 'professionalId': 'TP-1'},
          patient: const MedicalDocumentPatientEntity(
            name: 'Max',
            identifier: 'AR-MAX',
            species: 'Canino',
          ),
          owner: const MedicalDocumentOwnerEntity(
            name: 'John Doe',
            identification: 'C.C. 4567',
          ),
        ),
        _vaccinationDocument(
          id: 'rabies-new',
          vaccinationId: 'rabies-2',
          fields: const {
            'name': 'Rabia',
            'applicationDate': '10/27/2025',
            'nextDoseDate': '10/27/2028',
            'manufacturer': 'Medicine Lab',
          },
          issuer: const {'name': 'María Ríos', 'professionalId': 'TP-2'},
          patient: const MedicalDocumentPatientEntity(
            name: 'Brownie',
            identifier: 'AR-C012',
            species: 'Canino',
          ),
          owner: const MedicalDocumentOwnerEntity(
            name: 'Barbara James',
            identification: 'C.C. 1152234567',
          ),
        ),
      ], category: MedicalDocumentCategory.vaccinationCard),
    );
    when(() => documentsCubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      BlocProvider<AnimalMedicalDocumentsCubit>.value(
        value: documentsCubit,
        child: const MaterialApp(
          home: AnimalVaccinationsScreen(animal: animal),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final rabiesCard = find.byKey(const Key('vaccination-group-rabies'));
    await tester.tapAt(tester.getTopLeft(rabiesCard) + const Offset(30, 30));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('export-vaccination-group')), findsOneWidget);
    expect(find.text('Enviar'), findsOneWidget);
    expect(find.text('Detalle de vacunación'), findsNWidgets(2));
    expect(find.text('Next Dose Date'), findsOneWidget);
    expect(find.text('10/27/2028'), findsOneWidget);
    expect(find.text('Dosis 1'), findsOneWidget);
    expect(find.text('Dosis 2'), findsOneWidget);
    expect(find.text('Ver original'), findsNWidgets(2));
    expect(find.byType(Divider), findsNWidgets(2));
    expect(
      find.textContaining('María Ríos', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Juanita Doe', findRichText: true),
      findsOneWidget,
    );

    final firstRecord = find.byKey(
      const Key('vaccination-record-rabies-new-0'),
    );
    final secondRecord = find.byKey(
      const Key('vaccination-record-rabies-old-1'),
    );
    await tester.ensureVisible(secondRecord);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Barbara James', findRichText: true),
      findsNothing,
    );
    expect(find.textContaining('Brownie', findRichText: true), findsNothing);
    expect(find.textContaining('John Doe', findRichText: true), findsNothing);
    expect(find.textContaining('Max', findRichText: true), findsNothing);
    expect(
      find.textContaining('Propietario', findRichText: true),
      findsNothing,
    );
    expect(find.textContaining('Paciente', findRichText: true), findsNothing);
    expect(
      tester.getTopLeft(secondRecord).dy - tester.getBottomLeft(firstRecord).dy,
      AppSpacing.xl,
    );
    await tester.tap(find.byKey(const Key('export-vaccination-group')));
    await tester.pumpAndSettle();
    expect(find.text('Certificado de vacunación'), findsOneWidget);
    expect(
      find.byKey(const Key('vaccination-certificate-menu')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('vaccination-type-rabia')), findsOneWidget);
    expect(find.text('Dosis 1'), findsOneWidget);
    expect(find.text('Dosis 2'), findsOneWidget);
    expect(
      find.byKey(const Key('vaccination-card-footer-logo')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens doses that share the same medical document id', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final documentsCubit = MockAnimalMedicalDocumentsCubit();
    when(() => documentsCubit.state).thenReturn(
      AnimalMedicalDocumentsLoaded([
        _vaccinationDocument(
          id: 'shared-vaccine-document',
          vaccinationId: 'bordetella-1',
          fields: const {
            'name': 'BORDETELLA',
            'applicationDate': 'January 24, 2023',
          },
          additionalVaccinations: const [
            MedicalDocumentItemEntity(
              id: 'bordetella-2',
              fields: {
                'name': 'BORDETELLA',
                'applicationDate': 'January 24, 2024',
              },
            ),
          ],
        ),
      ], category: MedicalDocumentCategory.vaccinationCard),
    );
    when(() => documentsCubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      BlocProvider<AnimalMedicalDocumentsCubit>.value(
        value: documentsCubit,
        child: const MaterialApp(
          home: AnimalVaccinationsScreen(animal: animal),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('vaccination-group-bordetella')));
    await tester.pumpAndSettle();

    expect(find.text('Bordetella'), findsNWidgets(2));
    expect(find.text('BORDETELLA'), findsNothing);
    expect(
      find.byKey(const Key('vaccination-record-shared-vaccine-document-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('vaccination-record-shared-vaccine-document-1')),
      findsOneWidget,
    );
    expect(find.text('Dosis 1'), findsOneWidget);
    expect(find.text('Dosis 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

MedicalDocumentEntity _vaccinationDocument({
  required String id,
  required String vaccinationId,
  required Map<String, dynamic> fields,
  Map<String, dynamic>? issuer,
  MedicalDocumentPatientEntity? patient,
  MedicalDocumentOwnerEntity? owner,
  List<MedicalDocumentItemEntity> additionalVaccinations = const [],
}) {
  return MedicalDocumentEntity(
    id: id,
    animalIds: const ['animal-1'],
    originalFileName: '$id.pdf',
    mimeType: 'application/pdf',
    fileSize: 100,
    status: MedicalDocumentStatus.accepted,
    finalCategory: MedicalDocumentCategory.vaccinationCard,
    validatedExtraction: MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.vaccinationCard,
      issuer: issuer,
      patient: patient,
      owner: owner,
      vaccinations: [
        MedicalDocumentItemEntity(id: vaccinationId, fields: fields),
        ...additionalVaccinations,
      ],
    ),
    version: 1,
  );
}
