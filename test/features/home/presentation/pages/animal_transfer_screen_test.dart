import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/features/auth/presentation/widgets/id_selector.dart';
import 'package:animal_record/features/auth/presentation/widgets/register_steps/verification_step.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_cubit.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/fixtures/animal_transfer_preview_data.dart';
import 'package:animal_record/features/home/presentation/pages/animal_transfer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<AnimalTransferCubit> openFlow(
    WidgetTester tester, {
    int count = 1,
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = AnimalTransferCubit(
      animals: List.generate(count, _animal),
      recipients: animalTransferPreviewRecipients,
      transferReasons: animalTransferPreviewReasons,
      verificationIdentifier: animalTransferPreviewVerificationIdentifier,
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AnimalTransferScreen(),
                  ),
                ),
                child: const Text('Abrir transferencia'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir transferencia'));
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('searches, selects, confirms and returns without losing input', (
    tester,
  ) async {
    await openFlow(tester);
    expect(find.byKey(const Key('transfer-animal-animal-0')), findsOneWidget);
    expect(find.text('Bárbara James'), findsNothing);
    await tester.enterText(
      find.byKey(const Key('transfer-recipient-search')),
      'Barb',
    );
    await tester.pumpAndSettle();
    final button = find.byKey(const Key('transfer-select-recipient'));
    expect(tester.widget<CustomButton>(button).onPressed, isNull);
    final recipient = find.byKey(
      const Key('transfer-recipient-preview-recipient'),
    );
    await tester.ensureVisible(recipient);
    await tester.tap(recipient);
    await tester.pumpAndSettle();
    expect(tester.widget<CustomButton>(button).onPressed, isNotNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Confirmar usuario', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Solicita a Bárbara', findRichText: true),
      findsOneWidget,
    );
    final confirm = find.byKey(const Key('transfer-confirm'));
    expect(tester.widget<CustomButton>(confirm).onPressed, isNull);
    expect(
      tester.widget<IdSelector>(find.byType(IdSelector)).idTypeEnabled,
      isFalse,
    );
    final identification = find.descendant(
      of: find.byType(IdSelector),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(identification);
    await tester.enterText(identification, '1234567');
    await tester.pumpAndSettle();
    expect(tester.widget<CustomButton>(confirm).onPressed, isNull);
    await tester.ensureVisible(find.byKey(const Key('transfer-reason')));
    await tester.tap(find.text('Seleccionar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Venta'));
    await tester.pumpAndSettle();
    expect(tester.widget<CustomButton>(confirm).onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('transfer-confirm')));
    await tester.pumpAndSettle();
    expect(find.byType(VerificationStep), findsOneWidget);
    final verify = find.byKey(const Key('transfer-verify-code'));
    expect(tester.widget<CustomButton>(verify).onPressed, isNull);
    final code = find.descendant(
      of: find.byType(VerificationStep),
      matching: find.byType(TextField),
    );
    await tester.enterText(code, 'AB12');
    await tester.pumpAndSettle();
    expect(tester.widget<CustomButton>(verify).onPressed, isNull);
    await tester.enterText(code, 'AB123');
    await tester.pumpAndSettle();
    expect(tester.widget<CustomButton>(verify).onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('transfer-verification-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transfer-back')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('transfer-recipient-search')))
          .controller!
          .text,
      'Barb',
    );
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(identification).initialValue,
      '1234567',
    );
    expect(
      tester
          .widget<AppDropdown<String>>(find.byKey(const Key('transfer-reason')))
          .value,
      'Venta',
    );
    expect(tester.widget<CustomButton>(confirm).onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('transfer-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.text('Bárbara James'), findsNothing);
    expect(find.byKey(const Key('transfer-select-recipient')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expands all five animals in both steps on a small screen', (
    tester,
  ) async {
    final cubit = await openFlow(tester, count: 5, size: const Size(320, 640));
    final toggle = find.byKey(const Key('transfer-animals-toggle'));
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    for (var index = 0; index < 5; index++) {
      expect(find.byKey(Key('transfer-animal-animal-$index')), findsOneWidget);
    }
    cubit.search('Barb');
    cubit.selectRecipient(cubit.state.results.single);
    cubit.confirmRecipient();
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('transfer-animal-animal-4')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('transfer-confirm')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty search and cancellation leave the original route intact', (
    tester,
  ) async {
    await openFlow(tester);
    await tester.enterText(
      find.byKey(const Key('transfer-recipient-search')),
      'nadie',
    );
    await tester.pumpAndSettle();
    expect(find.text('No se encontraron usuarios'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(find.byType(AnimalTransferScreen), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí'));
    await tester.pumpAndSettle();
    expect(find.byType(AnimalTransferScreen), findsNothing);
    expect(find.text('Abrir transferencia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Other shows a required description field using the shared input',
    (tester) async {
      final cubit = await openFlow(tester);
      cubit.search('Barb');
      cubit.selectRecipient(cubit.state.results.single);
      cubit.confirmRecipient();
      cubit.updateIdentificationNumber('1234567');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('transfer-reason')));
      await tester.tap(find.text('Seleccionar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Otro'));
      await tester.pumpAndSettle();
      final other = find.byKey(const Key('transfer-other-reason'));
      final confirm = find.byKey(const Key('transfer-confirm'));
      expect(find.text('¿Cuál?', findRichText: true), findsOneWidget);
      expect(tester.widget<CustomButton>(confirm).onPressed, isNull);
      final input = find.descendant(
        of: other,
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(input);
      await tester.enterText(input, 'Cesión familiar');
      await tester.pumpAndSettle();
      expect(tester.widget<CustomButton>(confirm).onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('transfer-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('transfer-select-recipient')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<CustomTextField>(other).initialValue,
        'Cesión familiar',
      );
      await tester.ensureVisible(find.byKey(const Key('transfer-reason')));
      await tester.tap(find.text('Otro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Venta'));
      await tester.pumpAndSettle();
      expect(other, findsNothing);
      expect(cubit.state.otherReasonDetail, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('OTP resend clears the code and reuses the existing countdown', (
    tester,
  ) async {
    final cubit = await openFlow(tester);
    cubit.search('Barb');
    cubit.selectRecipient(cubit.state.results.single);
    cubit.confirmRecipient();
    cubit.updateIdentificationNumber('1234567');
    cubit.selectTransferReason('Venta');
    cubit.startVerification();
    await tester.pumpAndSettle();
    final otp = find.byType(VerificationStep);
    final shared = tester.widget<VerificationStep>(otp);
    expect(shared.identifier, animalTransferPreviewVerificationIdentifier);
    expect(shared.enableSmsAutofill, isFalse);
    await tester.enterText(
      find.descendant(of: otp, matching: find.byType(TextField)),
      'AB123',
    );
    await tester.pumpAndSettle();
    final resend = find.byKey(const Key('transfer-resend-code'));
    await tester.ensureVisible(resend);
    await tester.tap(resend);
    await tester.pump();
    expect(tester.state<VerificationStepState>(otp).getCode(), isEmpty);
    expect(tester.widget<TextButton>(resend).onPressed, isNull);
    expect(
      tester
          .widget<CustomButton>(find.byKey(const Key('transfer-verify-code')))
          .onPressed,
      isNull,
    );
    await tester.pump(const Duration(seconds: 181));
    await tester.pump();
    expect(tester.widget<TextButton>(resend).onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('transfer-verification-back')));
    await tester.pumpAndSettle();
    expect(find.byType(IdSelector), findsOneWidget);
    expect(cubit.state.identificationNumber, '1234567');
    expect(cubit.state.transferReason, 'Venta');
    expect(tester.takeException(), isNull);
  });
}

AnimalModel _animal(int index) => AnimalModel(
  id: 'animal-$index',
  name: 'Brownie $index',
  code: 'AR-C01$index',
  family: 'Canino',
  breed: 'Labrador',
  sex: 'macho',
  ageDisplay: '10 años',
);
