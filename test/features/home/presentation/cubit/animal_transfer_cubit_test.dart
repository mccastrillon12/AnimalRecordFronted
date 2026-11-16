import 'package:animal_record/features/home/presentation/cubit/animal_transfer_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_state.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/fixtures/animal_transfer_preview_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AnimalTransferCubit cubit;

  setUp(() {
    cubit = AnimalTransferCubit(
      animals: const [_animal],
      recipients: animalTransferPreviewRecipients,
      transferReasons: animalTransferPreviewReasons,
      verificationIdentifier: animalTransferPreviewVerificationIdentifier,
    );
  });
  tearDown(() => cubit.close());

  test('requires an explicit recipient selection and preserves it on back', () {
    cubit.confirmRecipient();
    expect(cubit.state.step, AnimalTransferStep.searchUser);
    cubit.search('  barb  ');
    expect(cubit.state.results.single.name, 'Bárbara James');
    expect(cubit.state.canContinue, isFalse);
    cubit.selectRecipient(cubit.state.results.single);
    cubit.confirmRecipient();
    expect(cubit.state.step, AnimalTransferStep.confirmUser);
    expect(cubit.state.animals.single, same(_animal));
    cubit.backToSearch();
    expect(cubit.state.query, '  barb  ');
    expect(cubit.state.selectedRecipient, isNotNull);
  });

  test('editing or clearing a query invalidates the prior selection', () {
    cubit.search('BÁRBARA');
    cubit.selectRecipient(cubit.state.results.single);
    cubit.search('No existe');
    expect(cubit.state.results, isEmpty);
    expect(cubit.state.canContinue, isFalse);
    cubit.selectRecipient(animalTransferPreviewRecipients.single);
    expect(cubit.state.selectedRecipient, isNull);
    cubit.search('');
    expect(cubit.state.results, isEmpty);
  });

  test(
    'requires identification and a listed reason before enabling transfer',
    () {
      cubit.search('Barb');
      cubit.selectRecipient(cubit.state.results.single);
      cubit.confirmRecipient();
      expect(cubit.state.canTransfer, isFalse);
      cubit.selectTransferReason('Motivo desconocido');
      expect(cubit.state.transferReason, isEmpty);
      cubit.updateIdentificationNumber('1234567');
      expect(cubit.state.canTransfer, isFalse);
      cubit.selectTransferReason('Venta');
      expect(cubit.state.canTransfer, isTrue);
      cubit.updateIdentificationNumber('');
      expect(cubit.state.canTransfer, isFalse);
      cubit.updateIdentificationNumber('   ');
      expect(cubit.state.canTransfer, isFalse);
      cubit.updateIdentificationNumber('123-456');
      expect(cubit.state.canTransfer, isFalse);
      cubit.updateIdentificationNumber('AB1234567');
      expect(cubit.state.canTransfer, isTrue);
      cubit.selectTransferReason(null);
      expect(cubit.state.canTransfer, isFalse);
    },
  );

  test(
    'keeps the form on back and clears it when searching for another user',
    () {
      cubit.search('Barb');
      cubit.selectRecipient(cubit.state.results.single);
      cubit.confirmRecipient();
      cubit.updateIdentificationNumber('1234567');
      cubit.selectTransferReason('Adopción');
      cubit.backToSearch();
      expect(cubit.state.canTransfer, isFalse);
      cubit.confirmRecipient();
      expect(cubit.state.identificationNumber, '1234567');
      expect(cubit.state.transferReason, 'Adopción');
      expect(cubit.state.canTransfer, isTrue);
      cubit.backToSearch();
      cubit.search('James');
      cubit.selectRecipient(cubit.state.results.single);
      cubit.confirmRecipient();
      expect(cubit.state.identificationNumber, isEmpty);
      expect(cubit.state.transferReason, isEmpty);
      expect(cubit.state.canTransfer, isFalse);
    },
  );

  test(
    'deduplicates input and excludes inactive animals without mutating it',
    () async {
      final animals = [
        _animal,
        _animal,
        const AnimalModel(
          id: 'inactive',
          name: 'Inactivo',
          code: 'AR-0002',
          family: 'Bovino',
          isActive: false,
        ),
      ];
      final other = AnimalTransferCubit(animals: animals);
      addTearDown(other.close);
      expect(other.state.animals, [_animal]);
      expect(animals, hasLength(3));
      expect(() => other.state.animals.clear(), throwsUnsupportedError);
      other.search('Barb');
      expect(other.state.results, isEmpty);
    },
  );

  test(
    'Other requires a description and clears it when choosing another reason',
    () {
      cubit.search('Barb');
      cubit.selectRecipient(cubit.state.results.single);
      cubit.confirmRecipient();
      cubit.updateIdentificationNumber('1234567');
      cubit.selectTransferReason('Otro');
      expect(cubit.state.requiresOtherReason, isTrue);
      expect(cubit.state.canTransfer, isFalse);
      cubit.updateOtherReasonDetail('   ');
      cubit.startVerification();
      expect(cubit.state.step, AnimalTransferStep.confirmUser);
      cubit.updateOtherReasonDetail('Cesión familiar');
      expect(cubit.state.canTransfer, isTrue);
      cubit.backToSearch();
      cubit.confirmRecipient();
      expect(cubit.state.otherReasonDetail, 'Cesión familiar');
      cubit.selectTransferReason('Venta');
      expect(cubit.state.otherReasonDetail, isEmpty);
      expect(cubit.state.canTransfer, isTrue);
      cubit.selectTransferReason('Otro');
      expect(cubit.state.canTransfer, isFalse);
    },
  );

  test('verification keeps the confirmation data when returning', () {
    cubit.search('Barb');
    cubit.selectRecipient(cubit.state.results.single);
    cubit.confirmRecipient();
    cubit.startVerification();
    expect(cubit.state.step, AnimalTransferStep.confirmUser);
    cubit.updateIdentificationNumber('1234567');
    cubit.selectTransferReason('Otro');
    cubit.updateOtherReasonDetail('Cesión familiar');
    cubit.startVerification();
    expect(cubit.state.step, AnimalTransferStep.verifyContact);
    expect(
      cubit.state.verificationIdentifier,
      animalTransferPreviewVerificationIdentifier,
    );
    cubit.backToConfirmation();
    expect(cubit.state.identificationNumber, '1234567');
    expect(cubit.state.transferReason, 'Otro');
    expect(cubit.state.otherReasonDetail, 'Cesión familiar');
    expect(cubit.state.canTransfer, isTrue);
  });

  test('completion preview requires the OTP step and a complete code', () {
    cubit.completePreview('AB123');
    expect(cubit.state.step, AnimalTransferStep.searchUser);
    cubit.search('Barb');
    cubit.selectRecipient(cubit.state.results.single);
    cubit.confirmRecipient();
    cubit.updateIdentificationNumber('1234567');
    cubit.selectTransferReason('Venta');
    cubit.startVerification();
    cubit.completePreview('AB12');
    expect(cubit.state.step, AnimalTransferStep.verifyContact);
    cubit.completePreview('AB12!');
    expect(cubit.state.step, AnimalTransferStep.verifyContact);
    cubit.completePreview('AB123');
    expect(cubit.state.step, AnimalTransferStep.completed);
    expect(cubit.state.selectedRecipient!.name, 'Bárbara James');
    expect(cubit.state.animals.single, same(_animal));
  });
}

const _animal = AnimalModel(
  id: 'animal-1',
  name: 'Brownie',
  code: 'AR-C012',
  family: 'Canino',
  breed: 'Labrador',
  sex: 'macho',
  ageDisplay: '10 años',
);
