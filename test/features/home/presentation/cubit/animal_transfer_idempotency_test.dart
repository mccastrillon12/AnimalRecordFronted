import 'package:animal_record/core/network/api_exception.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_recipient.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_cubit.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements AnimalTransferRepository {}

void main() {
  test(
    'cada transferencia nueva usa otra clave y el reintento conserva cuerpo y clave',
    () async {
      final repository = _Repository();
      final keys = <String>[];
      final bodies = <Map<String, Object>>[];
      registerFallbackValue(<String, Object>{});
      when(
        () => repository.createTransfer(
          idempotencyKey: any(named: 'idempotencyKey'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((invocation) async {
        keys.add(invocation.namedArguments[#idempotencyKey] as String);
        bodies.add(
          Map.of(invocation.namedArguments[#body] as Map<String, Object>),
        );
        if (keys.length == 1) {
          throw const ApiException(message: 'Incierto', statusCode: 503);
        }
        return TransferRequest(
          id: 'transfer-${keys.length}',
          status: 'PENDING',
          version: 1,
          recipientName: 'Destinatario',
        );
      });
      Future<AnimalTransferCubit> transferTo(String owner) async {
        final recipient = AnimalTransferRecipient(
          id: owner,
          name: 'Destinatario',
          identificationNumber: '1234',
          identificationType: 'CC',
        );
        when(
          () => repository.searchRecipients('Destinatario'),
        ).thenAnswer((_) async => TransferPage([recipient], null));
        when(() => repository.getReasons()).thenAnswer(
          (_) async => const [
            TransferReason(code: 'ADOPTION', name: 'Adopción'),
          ],
        );
        when(() => repository.startChallenge()).thenAnswer(
          (_) async => TransferChallenge(
            id: 'test-challenge',
            channel: 'EMAIL',
            maskedDestination: 'test',
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            resendAvailableAt: DateTime.now(),
          ),
        );
        when(
          () => repository.verifyChallenge('test-challenge', '12345'),
        ).thenAnswer(
          (_) async => TransferAuthorization(
            proof: 'test-only',
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
          ),
        );
        final cubit = AnimalTransferCubit(
          repository: repository,
          animals: const [
            AnimalModel(
              id: 'same-animal',
              name: 'Luna',
              code: 'AR-E018',
              family: 'Equino',
            ),
          ],
        );
        addTearDown(cubit.close);
        await cubit.loadReasons();
        await cubit.search('Destinatario');
        cubit.selectRecipient(recipient);
        cubit.confirmRecipient();
        cubit.updateIdentificationNumber('1234');
        cubit.selectTransferReason('ADOPTION');
        await cubit.startVerification();
        await cubit.verifyAndCreate('12345');
        return cubit;
      }

      final outgoing = await transferTo('owner-2');
      expect(outgoing.state.canRetryCreation, isTrue);
      await outgoing.retryCreation();
      expect(keys[0], keys[1]);
      expect(bodies[0], bodies[1]);
      await transferTo('owner-1');
      expect(keys[2], isNot(keys[0]));
      expect(bodies[2]['recipientId'], 'owner-1');
      expect(bodies[2]['animalIds'], bodies[0]['animalIds']);
    },
  );
}
