import 'package:animal_record/features/home/data/datasources/animal_transfer_remote_datasource.dart';
import 'package:animal_record/features/home/data/datasources/animal_remote_datasource.dart';
import 'package:animal_record/features/home/data/models/animal_data_model.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_recipient.dart';
import 'package:animal_record/features/home/domain/services/transfer_comment_policy.dart';
import 'package:animal_record/features/home/domain/entities/historical_file_download.dart';
import 'package:animal_record/features/home/domain/services/transfer_otp_policy.dart';

class AnimalTransferRepositoryImpl implements AnimalTransferRepository {
  final AnimalTransferRemoteDataSource remote;
  final AnimalRemoteDataSource animalsRemote;
  final void Function(Iterable<String> animalIds)? onOwnershipChanged;
  final _pendingOwnershipChanges =
      <String, ({int version, Set<String> animalIds})>{};
  final _reconciledOwnershipVersions = <String, int>{};
  int _sessionGeneration = 0;

  AnimalTransferRepositoryImpl(
    this.remote, {
    required this.animalsRemote,
    this.onOwnershipChanged,
  });

  @override
  void clearSessionState() {
    ++_sessionGeneration;
    _pendingOwnershipChanges.clear();
    _reconciledOwnershipVersions.clear();
  }

  @override
  Future<List<AnimalEntity>> getActiveAnimals() async {
    final items = await remote.getActiveAnimals();
    // Search results may omit ownership flags. Only the current own-animal
    // list can establish eligibility; a missing animal is never selectable.
    final eligibleIds = (await animalsRemote.getOwnAnimals())
        .where((animal) => animal.canTransfer)
        .map((animal) => animal.id)
        .toSet();
    return items
        .map((item) => AnimalDataModel.fromJson(item as Map<String, dynamic>))
        .where(
          (animal) => animal.canTransfer && eligibleIds.contains(animal.id),
        )
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
    return _reasons(await remote.getReasons());
  }

  @override
  Future<List<TransferReason>> getRejectionReasons() async =>
      _reasons(await remote.getRejectionReasons());

  List<TransferReason> _reasons(List<dynamic> items) {
    if (items.isEmpty) {
      throw const FormatException(
        'El servidor no tiene motivos disponibles. El administrador debe revisar el catálogo.',
      );
    }
    final reasons = items
        .map((item) {
          final json = item as Map<String, dynamic>;
          return TransferReason(
            code: json['code'] as String,
            name: json['name'] as String,
            requiresComment: json['requiresComment'] as bool? ?? false,
            sortOrder: json['sortOrder'] as int? ?? 0,
          );
        })
        .toList(growable: false);
    reasons.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return List.unmodifiable(reasons);
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
    if (!TransferOtpPolicy.isValid(code)) {
      throw const FormatException('El código debe tener cinco dígitos.');
    }
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
    final reasonCode = body['reasonCode'] as String;
    final comment = TransferCommentPolicy.normalize(
      reasonCode,
      body['reasonComment'] as String?,
    );
    // Only the documented client-controlled fields can reach this endpoint.
    final authorization = body['authorization'] as Map;
    final json = await remote.createTransfer(idempotencyKey, {
      'recipientId': body['recipientId'] as String,
      'reasonCode': reasonCode,
      if (comment != null) 'reasonComment': comment,
      'animalIds': List<String>.from(body['animalIds'] as List),
      'authorization': {
        'challengeId': authorization['challengeId'] as String,
        'proof': authorization['proof'] as String,
      },
    });
    return _request(json);
  }

  TransferRequest _request(Map<String, dynamic> json) => TransferRequest(
    id: json['id'] as String,
    status: json['status'] as String,
    version: json['version'] as int,
    recipientName: json['recipientName'] as String? ?? '',
    senderName: json['senderName'] as String? ?? '',
    reasonName: json['reasonName'] as String? ?? '',
    reasonCode: json['reasonCode'] as String?,
    reasonComment: json['reasonComment'] as String?,
    rejectionReasonCode: json['rejectionReasonCode'] as String?,
    rejectionComment: json['rejectionComment'] as String?,
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
    final generation = _sessionGeneration;
    final json = await remote.getDetail(id, cursor: cursor);
    final detail = TransferDetail(
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
    if (generation == _sessionGeneration) {
      _reconcileOwnershipChange(detail.request);
    }
    return detail;
  }

  void _reconcileOwnershipChange(TransferRequest request) {
    // Historical GETs have no invalidation side effects. Only decisions sent
    // during this session can produce a pending ownership-change event.
    final change = _pendingOwnershipChanges[request.id];
    if (change == null || request.version <= change.version) return;
    final received =
        request.status == 'ACCEPTED' || request.status == 'PARTIALLY_ACCEPTED';
    if (!received && request.status != 'REJECTED') return;
    _pendingOwnershipChanges.remove(request.id);
    if ((_reconciledOwnershipVersions[request.id] ?? -1) >= request.version) {
      return;
    }
    _reconciledOwnershipVersions[request.id] = request.version;
    if (received && change.animalIds.isNotEmpty) {
      onOwnershipChanged?.call(change.animalIds);
    }
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
    String? rejectionReasonCode,
    String? rejectionComment,
  }) async {
    if (rejectionReasonCode == null && rejectionComment != null) {
      throw const FormatException(
        'El comentario requiere un motivo de rechazo.',
      );
    }
    final comment = rejectionReasonCode == null
        ? null
        : TransferCommentPolicy.normalize(
            rejectionReasonCode,
            rejectionComment,
          );
    final generation = _sessionGeneration;
    _pendingOwnershipChanges[id] = (
      version: expectedVersion,
      animalIds: Set.unmodifiable(acceptedAnimalIds),
    );
    final request = _request(
      await remote.decide(
        id: id,
        expectedVersion: expectedVersion,
        acceptedAnimalIds: acceptedAnimalIds,
        idempotencyKey: idempotencyKey,
        rejectionReasonCode: rejectionReasonCode,
        rejectionComment: comment,
      ),
    );
    if (generation == _sessionGeneration) _reconcileOwnershipChange(request);
    return request;
  }

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
  Future<HistoricalFileDownload> downloadHistoricalFileData({
    required String periodId,
    required String publicationHash,
    required String entryId,
    required String fileId,
  }) => remote.downloadHistoricalFileData(
    periodId: periodId,
    publicationHash: publicationHash,
    entryId: entryId,
    fileId: fileId,
  );

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
