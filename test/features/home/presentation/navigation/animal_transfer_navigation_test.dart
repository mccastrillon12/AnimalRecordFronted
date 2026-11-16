import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_cubit.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/navigation/animal_transfer_navigation.dart';
import 'package:animal_record/features/home/presentation/navigation/home_section_navigation.dart';
import 'package:animal_record/features/auth/presentation/widgets/register_steps/verification_step.dart';
import 'package:animal_record/features/home/presentation/pages/animal_transfer_success_screen.dart';
import 'package:animal_record/features/home/presentation/pages/animal_detail_screen.dart';
import 'package:animal_record/features/home/presentation/pages/animal_transfer_screen.dart';
import 'package:animal_record/features/home/presentation/widgets/my_animals_content.dart';
import 'package:animal_record/features/shared_files/presentation/widgets/animal_selection_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnimalCubit extends Mock implements AnimalCubit {}

void main() {
  late _MockAnimalCubit animals;
  RouteSettings? homeDestinationSettings;

  setUp(() {
    animals = _MockAnimalCubit();
    homeDestinationSettings = null;
    when(() => animals.state).thenReturn(AnimalInitial());
    when(() => animals.stream).thenAnswer((_) => const Stream.empty());
    when(() => animals.animals).thenReturn([
      for (var index = 0; index < 5; index++) _entity(index),
      _entity(9, active: false),
    ]);
  });

  Future<void> pumpEntry(
    WidgetTester tester,
    Widget entry, {
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      BlocProvider<AnimalCubit>.value(
        value: animals,
        child: MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.animalTransfer) {
              return buildAnimalTransferRoute(settings);
            }
            if (settings.name == AppRoutes.home) {
              homeDestinationSettings = settings;
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const Scaffold(body: MyAnimalsContent()),
              );
            }
            return null;
          },
          home: entry,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> completeAndFinish(WidgetTester tester) async {
    final cubit = tester
        .element(find.byType(AnimalTransferScreen))
        .read<AnimalTransferCubit>();
    cubit.search('Barb');
    cubit.selectRecipient(cubit.state.results.single);
    cubit.confirmRecipient();
    cubit.updateIdentificationNumber('1234567');
    cubit.selectTransferReason('Venta');
    cubit.startVerification();
    await tester.pumpAndSettle();
    final code = find.descendant(
      of: find.byType(VerificationStep),
      matching: find.byType(TextField),
    );
    await tester.enterText(code, 'AB123');
    await tester.pumpAndSettle();
    final verify = find.byKey(const Key('transfer-verify-code'));
    await tester.ensureVisible(verify);
    await tester.tap(verify);
    await tester.pumpAndSettle();
    final success = find.byType(AnimalTransferSuccessScreen);
    expect(success, findsOneWidget);
    expect(find.text('Transferencia exitosa'), findsOneWidget);
    expect(
      find.textContaining('Bárbara James', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.descendant(of: success, matching: find.byType(ElevatedButton)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: success, matching: find.byType(IconButton)),
      findsNothing,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(success, findsOneWidget);
    await tester.tap(find.byKey(const Key('transfer-finish')));
    await tester.pumpAndSettle();
    expect(homeDestinationSettings!.name, AppRoutes.home);
    expect(homeDestinationSettings!.arguments, const {
      homeInitialSectionArgument: homeMyAnimalsSection,
    });
    expect(find.byType(MyAnimalsContent), findsOneWidget);
    expect(find.byType(AnimalTransferScreen), findsNothing);
    expect(find.byType(AnimalDetailScreen), findsNothing);
    expect(
      Navigator.of(tester.element(find.byType(MyAnimalsContent))).canPop(),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'My animals uses cached active animals and opens the shared route',
    (tester) async {
      await pumpEntry(tester, const Scaffold(body: MyAnimalsContent()));
      await tester.tap(find.byKey(const Key('my-animals-actions-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transferir animales'));
      await tester.pumpAndSettle();
      expect(find.byType(AnimalSelectionModal), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AnimalSelectionModal),
          matching: find.text('Bovinos'),
        ),
        findsOneWidget,
      );
      expect(find.text('0 seleccionados'), findsOneWidget);
      expect(find.textContaining('Vaca 9', findRichText: true), findsNothing);
      expect(
        tester.widget<CustomButton>(find.byType(CustomButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('Seleccionar todos'));
      await tester.pumpAndSettle();
      expect(find.text('5 seleccionados'), findsOneWidget);
      await tester.tap(find.text('Transferir'));
      await tester.pumpAndSettle();
      expect(find.byType(AnimalSelectionModal), findsNothing);
      expect(find.byType(AnimalTransferScreen), findsOneWidget);
      final context = tester.element(find.byType(AnimalTransferScreen));
      expect(ModalRoute.of(context)!.settings.name, AppRoutes.animalTransfer);
      expect(context.read<AnimalTransferCubit>().state.animals, hasLength(5));
      expect(find.text('Animales a transferir (5)'), findsOneWidget);
      verifyNever(() => animals.loadAnimals(any()));
      await completeAndFinish(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('detail skips selection and preserves the current animal model', (
    tester,
  ) async {
    const current = AnimalModel(
      id: 'current-animal',
      name: 'Brownie',
      code: 'AR-C012',
      family: 'Canino',
      ageDisplay: '10 años',
      breed: 'Labrador',
      sex: 'macho',
    );
    await pumpEntry(
      tester,
      const AnimalDetailScreen(animal: current),
      size: const Size(600, 1000),
    );
    await tester.ensureVisible(find.text('Transferir'));
    await tester.tap(find.text('Transferir'));
    await tester.pumpAndSettle();
    expect(find.byType(AnimalSelectionModal), findsNothing);
    final context = tester.element(find.byType(AnimalTransferScreen));
    expect(ModalRoute.of(context)!.settings.name, AppRoutes.animalTransfer);
    expect(
      context.read<AnimalTransferCubit>().state.animals.single,
      same(current),
    );
    expect(
      find.descendant(
        of: find.byType(AnimalTransferScreen),
        matching: find.text('10 años'),
      ),
      findsOneWidget,
    );
    expect(find.text('Labrador - Macho'), findsOneWidget);
    await completeAndFinish(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'closing selection or having no active animals never opens the flow',
    (tester) async {
      when(() => animals.animals).thenReturn([_entity(9, active: false)]);
      await pumpEntry(tester, const Scaffold(body: MyAnimalsContent()));
      await tester.tap(find.byKey(const Key('my-animals-actions-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transferir animales'));
      await tester.pumpAndSettle();
      expect(find.text('No se encontraron animales'), findsWidgets);
      expect(
        tester.widget<CustomButton>(find.byType(CustomButton)).onPressed,
        isNull,
      );
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(AnimalTransferScreen), findsNothing);
      expect(find.byType(MyAnimalsContent), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

AnimalEntity _entity(int index, {bool active = true}) => AnimalEntity(
  id: 'animal-$index',
  name: 'Vaca $index',
  code: 'AR-B01$index',
  species: 'BOVINE',
  breed: 'Angus',
  sex: 'MALE',
  reproductiveStatus: 'INTACT',
  hasChip: false,
  isAssociationMember: false,
  temperament: const [],
  diagnosis: const [],
  ownerId: 'owner-1',
  isActive: active,
);
