import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/home/presentation/widgets/navigation_menu.dart';
import 'package:animal_record/features/home/presentation/widgets/vaccination_cards_content.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/medical_field_catalog_test_data.dart';

class MockAnimalCubit extends Mock implements AnimalCubit {}

class MockGetAnimalMedicalDocumentsUseCase extends Mock
    implements GetAnimalMedicalDocumentsUseCase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(registerMedicalFieldCatalogTestDependencies);
  tearDown(unregisterMedicalFieldCatalogTestDependencies);

  testWidgets('shows animals by family with their vaccination summary', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const brownie = AnimalEntity(
      id: 'brownie-id',
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
    const lukas = AnimalEntity(
      id: 'lukas-id',
      name: 'Lukas',
      code: 'AR-C013',
      species: 'DOG',
      breed: 'Criollo',
      sex: 'MALE',
      reproductiveStatus: 'INTACT',
      hasChip: false,
      isAssociationMember: false,
      temperament: [],
      diagnosis: [],
      ownerId: 'owner-1',
    );
    final animalCubit = MockAnimalCubit();
    when(
      () => animalCubit.state,
    ).thenReturn(const AnimalsLoaded([brownie, lukas]));
    when(() => animalCubit.stream).thenAnswer((_) => const Stream.empty());

    final documentsUseCase = MockGetAnimalMedicalDocumentsUseCase();
    when(
      () => documentsUseCase(
        'brownie-id',
        category: MedicalDocumentCategory.vaccinationCard,
      ),
    ).thenAnswer((_) async => [_rabiesDocument]);
    when(
      () => documentsUseCase(
        'lukas-id',
        category: MedicalDocumentCategory.vaccinationCard,
      ),
    ).thenAnswer((_) async => []);

    await tester.pumpWidget(
      BlocProvider<AnimalCubit>.value(
        value: animalCubit,
        child: MaterialApp(
          home: Scaffold(
            body: VaccinationCardsContent(
              createDocumentsCubit: () => AnimalMedicalDocumentsCubit(
                getDocumentsUseCase: documentsUseCase,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Carné vacunas'), findsOneWidget);
    expect(find.text('Caninos'), findsOneWidget);
    expect(find.text('Brownie'), findsOneWidget);
    expect(find.text('AR-C012'), findsOneWidget);
    expect(find.text('Rabies'), findsOneWidget);
    expect(find.text('August 12, 2027'), findsOneWidget);
    expect(find.text('Lukas'), findsOneWidget);
    expect(find.text('No tiene dosis pendiente'), findsOneWidget);
    final titleRect = tester.getRect(
      find.byKey(const Key('vaccination-cards-title')),
    );
    final searchRect = tester.getRect(
      find.byKey(const Key('vaccination-cards-search-field')),
    );
    final familyRect = tester.getRect(
      find.byKey(const Key('vaccination-family-Caninos')),
    );
    expect(titleRect.left, AppSpacing.l);
    expect(searchRect.left, AppSpacing.l);
    expect(searchRect.top - titleRect.bottom, AppSpacing.l);
    expect(familyRect.top - searchRect.bottom, AppSpacing.m);
    expect(tester.getTopLeft(find.text('Caninos')).dx, AppSpacing.l * 2);

    await tester.enterText(
      find.byKey(const Key('vaccination-cards-search-field')),
      'Lukas',
    );
    await tester.pumpAndSettle();
    expect(find.text('Brownie'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('vaccination-animal-lukas-id')),
        matching: find.text('Lukas'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const Key('vaccination-cards-search-field')),
      '1234567890123456789012345',
    );
    await tester.pump();
    final searchField = tester.widget<TextField>(
      find.byKey(const Key('vaccination-cards-search-field')),
    );
    expect(searchField.controller?.text, '12345678901234567890');
  });

  testWidgets('main vaccination item selects the vaccination cards section', (
    tester,
  ) async {
    String? selectedSection;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NavigationMenu(
            onSectionChanged: (section) => selectedSection = section,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('navigation-vaccination-cards')));
    await tester.pump();

    expect(selectedSection, 'vaccination_cards');
  });
}

const _rabiesDocument = MedicalDocumentEntity(
  id: 'rabies-document',
  animalIds: ['brownie-id'],
  originalFileName: 'rabies.pdf',
  mimeType: 'application/pdf',
  fileSize: 100,
  status: MedicalDocumentStatus.accepted,
  finalCategory: MedicalDocumentCategory.vaccinationCard,
  validatedExtraction: MedicalDocumentExtractionEntity(
    documentType: MedicalDocumentCategory.vaccinationCard,
    vaccinations: [
      MedicalDocumentItemEntity(
        id: 'rabies-dose',
        fields: {
          'name': 'Rabies',
          'applicationDate': 'August 12, 2026',
          'nextDoseDate': 'August 12, 2027',
        },
      ),
    ],
  ),
  version: 1,
);
