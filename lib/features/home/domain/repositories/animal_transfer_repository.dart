import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_recipient.dart';

abstract class AnimalTransferRepository {
  Future<List<AnimalEntity>> getActiveAnimals();
  Future<TransferPage<AnimalTransferRecipient>> searchRecipients(
    String name, {
    String? cursor,
  });
  Future<List<TransferReason>> getReasons();
  Future<TransferChallenge> startChallenge();
  Future<TransferChallenge> resendChallenge(String challengeId);
  Future<TransferAuthorization> verifyChallenge(
    String challengeId,
    String code,
  );
  Future<TransferRequest> createTransfer({
    required String idempotencyKey,
    required Map<String, Object> body,
  });
  Future<TransferPage<TransferRequest>> listRequests({
    required String direction,
    String? status,
    String? cursor,
  });
  Future<TransferDetail> getDetail(String id, {String? cursor});
  Future<TransferRequest> decide({
    required String id,
    required int expectedVersion,
    required List<String> acceptedAnimalIds,
    required String idempotencyKey,
  });
  Future<TransferPage<OwnershipPeriod>> listHistory({String? cursor});
  Future<TransferPage<HistoricalEntry>> getHistory(
    String periodId,
    String publicationHash, {
    String? cursor,
  });
  Future<List<int>> downloadHistoricalFile({
    required String periodId,
    required String publicationHash,
    required String entryId,
    required String fileId,
  });
  Future<TransferPage<NotificationItem>> listNotifications({String? cursor});
  Future<int> unreadNotificationCount();
  Future<NotificationItem> markNotificationRead(String id);
}
