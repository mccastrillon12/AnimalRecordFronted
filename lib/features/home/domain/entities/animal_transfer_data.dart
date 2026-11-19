import 'package:equatable/equatable.dart';

class TransferReason extends Equatable {
  final String code;
  final String name;

  const TransferReason({required this.code, required this.name});

  @override
  List<Object> get props => [code, name];
}

class TransferChallenge extends Equatable {
  final String id;
  final String channel;
  final String maskedDestination;
  final DateTime expiresAt;
  final DateTime resendAvailableAt;

  const TransferChallenge({
    required this.id,
    required this.channel,
    required this.maskedDestination,
    required this.expiresAt,
    required this.resendAvailableAt,
  });

  @override
  List<Object> get props => [
    id,
    channel,
    maskedDestination,
    expiresAt,
    resendAvailableAt,
  ];
}

class TransferAuthorization {
  final String proof;
  final DateTime expiresAt;

  const TransferAuthorization({required this.proof, required this.expiresAt});
}

class TransferRequest extends Equatable {
  final String id;
  final String status;
  final int version;
  final String recipientName;
  final String senderName;
  final String reasonName;
  final int animalCount;
  final DateTime? decidedAt;

  const TransferRequest({
    required this.id,
    required this.status,
    required this.version,
    required this.recipientName,
    this.senderName = '',
    this.reasonName = '',
    this.animalCount = 0,
    this.decidedAt,
  });

  @override
  List<Object?> get props => [
    id,
    status,
    version,
    recipientName,
    senderName,
    reasonName,
    animalCount,
    decidedAt,
  ];
}

sealed class TransferAnimalAge extends Equatable {
  const TransferAnimalAge();
}

class ExactTransferAnimalAge extends TransferAnimalAge {
  final int months;
  const ExactTransferAnimalAge(this.months);

  @override
  List<Object> get props => [months];
}

class ApproximateTransferAnimalAge extends TransferAnimalAge {
  final int minMonths;
  final int maxMonths;

  const ApproximateTransferAnimalAge(this.minMonths, this.maxMonths);

  @override
  List<Object> get props => [minMonths, maxMonths];
}

class TransferItem extends Equatable {
  final String id;
  final String animalId;
  final String animalName;
  final String animalCode;
  final String? animalSpecies;
  final String? animalBreed;
  final String? animalSex;
  final String? animalImageUrl;
  final TransferAnimalAge? animalAge;
  final String status;

  const TransferItem({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.animalCode,
    this.animalSpecies,
    this.animalBreed,
    this.animalSex,
    this.animalImageUrl,
    this.animalAge,
    required this.status,
  });

  TransferItem withAnimalImageUrl(String imageUrl) => TransferItem(
    id: id,
    animalId: animalId,
    animalName: animalName,
    animalCode: animalCode,
    animalSpecies: animalSpecies,
    animalBreed: animalBreed,
    animalSex: animalSex,
    animalImageUrl: imageUrl,
    animalAge: animalAge,
    status: status,
  );

  @override
  List<Object?> get props => [
    id,
    animalId,
    animalName,
    animalCode,
    animalSpecies,
    animalBreed,
    animalSex,
    animalImageUrl,
    animalAge,
    status,
  ];
}

class TransferPage<T> {
  final List<T> items;
  final String? nextCursor;
  const TransferPage(this.items, this.nextCursor);
}

class TransferDetail {
  final TransferRequest request;
  final TransferPage<TransferItem> page;
  const TransferDetail(this.request, this.page);
}

class OwnershipPeriod extends Equatable {
  final String periodId;
  final String animalId;
  final String publicationHash;
  final DateTime endedAt;
  const OwnershipPeriod({
    required this.periodId,
    required this.animalId,
    required this.publicationHash,
    required this.endedAt,
  });

  @override
  List<Object> get props => [periodId, animalId, publicationHash, endedAt];
}

class HistoricalFile extends Equatable {
  final String fileId;
  final String? path;
  const HistoricalFile(this.fileId, this.path);

  @override
  List<Object?> get props => [fileId, path];
}

class HistoricalEntry extends Equatable {
  final String entryId;
  final String kind;
  final Map<String, dynamic> data;
  final List<HistoricalFile> media;
  const HistoricalEntry({
    required this.entryId,
    required this.kind,
    required this.data,
    required this.media,
  });

  @override
  List<Object> get props => [entryId, kind, data, media];
}

class NotificationItem extends Equatable {
  final String id;
  final String transferId;
  final String title;
  final String text;
  final DateTime? readAt;
  const NotificationItem({
    required this.id,
    required this.transferId,
    required this.title,
    required this.text,
    this.readAt,
  });

  @override
  List<Object?> get props => [id, transferId, title, text, readAt];
}
