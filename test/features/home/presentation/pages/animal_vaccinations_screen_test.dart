import 'package:animal_record/core/theme/app_typography.dart';
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
}
