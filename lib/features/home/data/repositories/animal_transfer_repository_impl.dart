import 'package:animal_record/features/home/data/datasources/animal_transfer_remote_datasource.dart';
import 'package:animal_record/features/home/data/models/animal_data_model.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_recipient.dart';

class AnimalTransferRepositoryImpl implements AnimalTransferRepository {
  final AnimalTransferRemoteDataSource remote;

  const AnimalTransferRepositoryImpl(this.remote);

  @override
  Future<List<AnimalEntity>> getActiveAnimals() async {
    final items = await remote.getActiveAnimals();
    return items
        .map((item) => AnimalDataModel.fromJson(item as Map<String, dynamic>))
        .where((animal) => animal.canTransfer)
        .toList(growable: false);
  }

  @override
  Future<TransferPage<AnimalTransferRecipient>> searchRecipients(
    String name, {
    String? cursor,
  }) async {
    final data = await remote.searchRecipients(name, cursor: cursor);
    final items = data['items'] as List<dynamic>;
    final recipients = items
        .map((item) {
          final json = item as Map<String, dynamic>;
          return AnimalTransferRecipient(
            id: json['id'] as String,
            name: json['name'] as String,
            identificationNumber: json['identificationNumber'] as String,
            identificationType: switch (json['identificationType']) {
              'CC' => 'C.C.',
              'CE' => 'C.E.',
              'PASSPORT' => 'Pasaporte',
              _ => json['identificationType'] as String,
            },
            imageUrl: json['profilePictureUrl'] as String?,
          );
        })
        .toList(growable: false);
    return TransferPage(recipients, data['nextCursor'] as String?);
  }

  @override
  Future<List<TransferReason>> getReasons() async {
    final items = await remote.getReasons();
    return items
        .map((item) {
          final json = item as Map<String, dynamic>;
          return TransferReason(
            code: json['code'] as String,
            name: json['name'] as String,
          );
        })
        .toList(growable: false);
  }

  TransferChallenge _challenge(Map<String, dynamic> json) => TransferChallenge(
    id: json['challengeId'] as String,
    channel: json['channel'] as String,
    maskedDestination: json['maskedDestination'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    resendAvailableAt: DateTime.parse(json['resendAvailableAt'] as String),
  );

  @override
  Future<TransferChallenge> startChallenge() async =>
      _challenge(await remote.startChallenge());

  @override
  Future<TransferChallenge> resendChallenge(String challengeId) async =>
      _challenge(await remote.resendChallenge(challengeId));

  @override
  Future<TransferAuthorization> verifyChallenge(
    String challengeId,
    String code,
  ) async {
    final json = await remote.verifyChallenge(challengeId, code);
    if (json['challengeId'] != challengeId ||
        json['purpose'] != 'ANIMAL_TRANSFER') {
      throw const FormatException('Prueba de transferencia inválida');
    }
    final proof = json['proof'] as String?;
    if (proof == null || proof.isEmpty) {
      throw const FormatException('Prueba de transferencia vacía');
    }
    return TransferAuthorization(
      proof: proof,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  @override
  Future<TransferRequest> createTransfer({
    required String idempotencyKey,
    required Map<String, Object> body,
  }) async {
    final json = await remote.createTransfer(idempotencyKey, body);
    return _request(json);
  }

  TransferRequest _request(Map<String, dynamic> json) => TransferRequest(
    id: json['id'] as String,
    status: json['status'] as String,
    version: json['version'] as int,
    recipientName: json['recipientName'] as String? ?? '',
    senderName: json['senderName'] as String? ?? '',
    reasonName: json['reasonName'] as String? ?? '',
    animalCount: json['animalCount'] as int? ?? 0,
    decidedAt: DateTime.tryParse(json['decidedAt'] as String? ?? ''),
  );

  TransferPage<T> _page<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>) parse,
  ) => TransferPage(
    (json[key] as List<dynamic>? ?? const [])
        .map((item) => parse(item as Map<String, dynamic>))
        .toList(growable: false),
    json['nextCursor'] as String?,
  );

  @override
  Future<TransferPage<TransferRequest>> listRequests({
    required String direction,
    String? status,
    String? cursor,
  }) async => _page(
    await remote.listRequests(
      direction: direction,
      status: status,
      cursor: cursor,
    ),
    'items',
    _request,
  );

  @override
  Future<TransferDetail> getDetail(String id, {String? cursor}) async {
    final json = await remote.getDetail(id, cursor: cursor);
    return TransferDetail(
      _request(json['request'] as Map<String, dynamic>),
      _page(
        json,
        'items',
        (item) => TransferItem(
          id: item['id'] as String,
          animalId: item['animalId'] as String,
          animalName: item['animalName'] as String? ?? '',
          animalCode: item['animalCode'] as String? ?? '',
          animalSpecies: (item['animalSpecies'] ?? item['species']) as String?,
          animalBreed: item['animalBreed'] as String?,
          animalSex: item['animalSex'] as String?,
          animalImageUrl: item['animalProfilePictureUrl'] as String?,
          animalAge: _animalAge(item['animalAge']),
          status: item['status'] as String,
        ),
      ),
    );
  }

  TransferAnimalAge? _animalAge(Object? json) => switch (json) {
    {'minMonths': final int min, 'maxMonths': final int max}
        when min >= 0 && max >= min =>
      ApproximateTransferAnimalAge(min, max),
    {'months': final int months} when months >= 0 => ExactTransferAnimalAge(
      months,
    ),
    _ => null,
  };

  @override
  Future<TransferRequest> decide({
    required String id,
    required int expectedVersion,
    required List<String> acceptedAnimalIds,
    required String idempotencyKey,
  }) async => _request(
    await remote.decide(
      id: id,
      expectedVersion: expectedVersion,
      acceptedAnimalIds: acceptedAnimalIds,
      idempotencyKey: idempotencyKey,
    ),
  );

  @override
  Future<TransferPage<OwnershipPeriod>> listHistory({String? cursor}) async {
    final json = await remote.listHistory(cursor: cursor);
    return _page(
      json,
      'periods',
      (period) => OwnershipPeriod(
        periodId: period['periodId'] as String,
        animalId: period['animalId'] as String,
        publicationHash: period['publicationHash'] as String,
        endedAt: DateTime.parse(period['endedAt'] as String),
      ),
    );
  }

  @override
  Future<TransferPage<HistoricalEntry>> getHistory(
    String periodId,
    String publicationHash, {
    String? cursor,
  }) async {
    final json = await remote.getHistory(
      periodId,
      publicationHash,
      cursor: cursor,
    );
    return _page(
      json,
      'entries',
      (entry) => HistoricalEntry(
        entryId: entry['entryId'] as String,
        kind: entry['kind'] as String,
        data: entry['data'] as Map<String, dynamic>? ?? const {},
        media: (entry['media'] as List<dynamic>? ?? const [])
            .map((item) {
              final file = item as Map<String, dynamic>;
              return HistoricalFile(
                file['fileId'] as String,
                file['path'] as String?,
              );
            })
            .toList(growable: false),
      ),
    );
  }

  @override
  Future<List<int>> downloadHistoricalFile({
    required String periodId,
    required String publicationHash,
    required String entryId,
    required String fileId,
  }) => remote.downloadHistoricalFile(
    periodId: periodId,
    publicationHash: publicationHash,
    entryId: entryId,
    fileId: fileId,
  );

  NotificationItem _notification(Map<String, dynamic> json) => NotificationItem(
    id: json['id'] as String,
    transferId: json['transferId'] as String,
    title: json['title'] as String? ?? '',
    text: json['text'] as String? ?? '',
    readAt: DateTime.tryParse(json['readAt'] as String? ?? ''),
  );

  @override
  Future<TransferPage<NotificationItem>> listNotifications({
    String? cursor,
  }) async => _page(
    await remote.listNotifications(cursor: cursor),
    'items',
    _notification,
  );

  @override
  Future<int> unreadNotificationCount() => remote.unreadNotificationCount();

  @override
  Future<NotificationItem> markNotificationRead(String id) async =>
      _notification(await remote.markNotificationRead(id));
}
