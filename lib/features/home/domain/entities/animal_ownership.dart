import 'package:equatable/equatable.dart';
import 'animal_transfer_data.dart';

class HistoricalFileReference extends Equatable {
  final String periodId;
  final String publicationHash;
  final String entryId;
  final String fileId;
  const HistoricalFileReference({
    required this.periodId,
    required this.publicationHash,
    required this.entryId,
    required this.fileId,
  });
  @override
  List<Object?> get props => [periodId, publicationHash, entryId, fileId];
}

class AnimalOwnershipHistory extends Equatable {
  final String periodId;
  final String publicationHash;
  final DateTime? transferredAt;
  final HistoricalFileReference? photo;
  final List<HistoricalEntry>? entries;
  const AnimalOwnershipHistory({
    required this.periodId,
    required this.publicationHash,
    this.transferredAt,
    this.photo,
    this.entries,
  });
  bool get isLoaded => entries != null;
  AnimalOwnershipHistory withoutEntries() => AnimalOwnershipHistory(
    periodId: periodId,
    publicationHash: publicationHash,
    transferredAt: transferredAt,
    photo: photo,
  );

  factory AnimalOwnershipHistory.fromJson(Map<String, dynamic> json) {
    final period = json['periodId'] as String;
    final hash = json['publicationHash'] as String;
    final photo = json['photo'];
    return AnimalOwnershipHistory(
      periodId: period,
      publicationHash: hash,
      transferredAt: DateTime.tryParse(json['transferredAt'] as String? ?? ''),
      photo:
          photo is Map &&
              photo['entryId'] is String &&
              photo['fileId'] is String
          ? HistoricalFileReference(
              periodId: period,
              publicationHash: hash,
              entryId: photo['entryId'],
              fileId: photo['fileId'],
            )
          : null,
    );
  }

  AnimalOwnershipHistory withEntries(List<HistoricalEntry> values) =>
      AnimalOwnershipHistory(
        periodId: periodId,
        publicationHash: publicationHash,
        transferredAt: transferredAt,
        photo: photo,
        entries: List.unmodifiable(values),
      );
  HistoricalFileReference file(HistoricalEntry entry, HistoricalFile file) =>
      HistoricalFileReference(
        periodId: periodId,
        publicationHash: publicationHash,
        entryId: entry.entryId,
        fileId: file.fileId,
      );
  @override
  List<Object?> get props => [
    periodId,
    publicationHash,
    transferredAt,
    photo,
    entries,
  ];
}

bool historicalAnimal(String? status, bool readOnly) =>
    readOnly || status == 'TRANSFERRED';
bool writableAnimal(String? status, bool readOnly) =>
    !historicalAnimal(status, readOnly) &&
    status != 'PENDING' &&
    status != 'PROCESSING';
