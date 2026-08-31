import 'package:animal_record/features/auth/domain/entities/user_entity.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/pages/vaccination_card_screen.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/layout/app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAnimalMedicalDocumentsCubit extends Mock
    implements AnimalMedicalDocumentsCubit {}

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the app profile and every vaccination in the card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const animal = AnimalModel(
      id: 'animal-1',
      name: 'Brownie',
      code: 'AR-C012',
      family: 'Canino',
      breed: 'Labrador',
      sex: 'macho',
      ageDisplay: '10 años',
      weight: 15,
    );
    const user = UserEntity(
      id: 'user-1',
      name: 'Barbara James',
      identificationType: 'C.C.',
      identificationNumber: '1152234567',
      country: 'Colombia',
      countryId: 'CO',
      departmentId: 'ANT',
      city: 'Medellín',
      cityId: 'MED',
      email: 'barbara@example.com',
      cellPhone: '3124567890',
      animalTypes: [],
      services: [],
      isHomeDelivery: false,
      roles: [],
      authMethod: 'email',
      isVerified: true,
    );
    final documentsCubit = MockAnimalMedicalDocumentsCubit();
    when(() => documentsCubit.state).thenReturn(
      AnimalMedicalDocumentsLoaded([
        _vaccinationDocument(
          id: 'rabies-new',
          vaccinationId: 'rabies-2',
          name: 'Rabia',
          applicationDate: '7/01/25',
          nextDoseDate: '7/01/26',
        ),
        _vaccinationDocument(
          id: 'rabies-old',
          vaccinationId: 'rabies-1',
          name: 'Rabies',
          applicationDate: '6/10/24',
        ),
        _vaccinationDocument(
          id: 'parvo',
          vaccinationId: 'parvo-1',
          name: 'Parvovirus',
          applicationDate: '5/01/25',
        ),
      ], category: MedicalDocumentCategory.vaccinationCard),
    );
    when(() => documentsCubit.stream).thenAnswer((_) => const Stream.empty());
    final authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(AuthSuccess(user));
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AnimalMedicalDocumentsCubit>.value(
            value: documentsCubit,
          ),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: const MaterialApp(home: VaccinationCardScreen(animal: animal)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Carné de vacunación'), findsOneWidget);
    expect(find.byType(AppHeader), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const Key('vaccination-card-logo-top-spacing')))
          .height,
      AppSpacing.xxl,
    );
    expect(
      tester
          .getSize(find.byKey(const Key('vaccination-card-title-spacing')))
          .height,
      AppSpacing.m,
    );
    final fixedContentGap = find.byKey(
      const Key('vaccination-card-fixed-content-gap'),
    );
    expect(tester.getSize(fixedContentGap).height, AppSpacing.xl);
    final gapRectBeforeScroll = tester.getRect(fixedContentGap);
    final title = tester.widget<Text>(
      find.byKey(const Key('vaccination-card-title')),
    );
    expect(title.style?.fontSize, AppTypography.heading1.fontSize);
    expect(title.style?.fontWeight, AppTypography.heading1.fontWeight);
    expect(
      find.byKey(const Key('vaccination-card-background')),
      findsOneWidget,
    );
    final contentBackground = tester.widget<Container>(
      find.byKey(const Key('vaccination-card-content-background')),
    );
    final backgroundDecoration = contentBackground.decoration! as BoxDecoration;
    expect(backgroundDecoration.color, AppColors.bgHielo);
    expect(backgroundDecoration.borderRadius, BorderRadius.circular(16));
    final contentRect = tester.getRect(
      find.byKey(const Key('vaccination-card-content-background')),
    );
    expect(contentRect.left, 22);
    expect(contentRect.right, 390 - 22);
    expect(
      find.byKey(const Key('vaccination-card-animal-photo-fallback')),
      findsOneWidget,
    );
    final animalPhoto = tester.widget<ClipRRect>(
      find.byKey(const Key('vaccination-card-animal-photo-card')),
    );
    expect(animalPhoto.borderRadius, BorderRadius.circular(16));
    expect(
      find.textContaining('Paciente Brownie', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Propietario Barbara James', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('C.C. 1152234567'), findsOneWidget);
    expect(find.text('barbara@example.com'), findsOneWidget);
    expect(find.text('Vacuna'), findsNWidgets(2));
    expect(find.text('Dosis 1'), findsNWidgets(2));
    expect(find.text('Dosis 2'), findsOneWidget);
    expect(find.text('7/01/25'), findsOneWidget);
    expect(find.text('7/01/26'), findsOneWidget);
    final photo = find.byKey(const Key('vaccination-card-animal-photo-card'));
    final profile = find.byKey(const Key('vaccination-card-app-information'));
    final vaccination = find.byKey(const Key('vaccination-type-rabia'));
    final previousVaccination = find.byKey(
      const Key('vaccination-type-parvovirus'),
    );
    expect(tester.getTopLeft(profile).dy - tester.getBottomLeft(photo).dy, 20);
    expect(
      tester.getTopLeft(vaccination).dy - tester.getBottomLeft(profile).dy,
      20,
    );
    expect(
      tester.getTopLeft(previousVaccination).dy -
          tester.getBottomLeft(vaccination).dy,
      20,
    );
    expect(
      find.byKey(const Key('vaccination-card-footer-logo')),
      findsOneWidget,
    );
    final sendMenu = tester.widget<PopupMenuButton<String>>(
      find.byKey(const Key('vaccination-card-menu')),
    );
    expect(
      (sendMenu.shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.zero,
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(fixedContentGap), gapRectBeforeScroll);
    await tester.tap(find.byKey(const Key('vaccination-card-menu')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('send-vaccination-document-menu-item')),
      findsOneWidget,
    );
    final triggerRect = tester.getRect(
      find.byKey(const Key('vaccination-card-menu')),
    );
    final menuRect = tester.getRect(
      find.byKey(const Key('send-vaccination-document-menu-item')),
    );
    expect(
      (menuRect.right - triggerRect.center.dx).abs(),
      lessThanOrEqualTo(2),
    );
    expect(menuRect.width, 128);
    expect(
      menuRect.top - triggerRect.bottom,
      inInclusiveRange(0, AppSpacing.xs),
    );
    expect(tester.takeException(), isNull);
  });
}

MedicalDocumentEntity _vaccinationDocument({
  required String id,
  required String vaccinationId,
  required String name,
  required String applicationDate,
  String? nextDoseDate,
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
      vaccinations: [
        MedicalDocumentItemEntity(
          id: vaccinationId,
          fields: {
            'name': name,
            'applicationDate': applicationDate,
            if (nextDoseDate != null) 'nextDoseDate': nextDoseDate,
            'brand': 'Virbac',
          },
        ),
      ],
    ),
    version: 1,
  );
}
