import 'package:animal_record/features/home/domain/entities/animal_ownership.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/data/models/animal_data_model.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/diary/data/models/diary_entry_model.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/medical_documents/data/models/medical_document_model.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';

class AnimalHistorySnapshot {
  static Future<AnimalOwnershipHistory> load(
    AnimalOwnershipHistory history,
    AnimalTransferRepository repository,
  ) async {
    if (history.isLoaded) return history;
    final entries = <HistoricalEntry>[];
    final cursors = <String>{};
    String? cursor;
    do {
      final page = await repository.getHistory(
        history.periodId,
        history.publicationHash,
        cursor: cursor,
      );
      entries.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor != null && !cursors.add(cursor)) {
        throw const FormatException(
          'No se pudo completar la consulta del expediente.',
        );
      }
    } while (cursor != null);
    HistoricalFileReference? photo = history.photo;
    for (final entry in entries.where((entry) => entry.kind == 'ANIMAL')) {
      for (final file in entry.media) {
        if (file.path == 'profilePictureUrl' || file.path == 'profilePicture') {
          photo ??= history.file(entry, file);
        }
      }
    }
    return AnimalOwnershipHistory(
      periodId: history.periodId,
      publicationHash: history.publicationHash,
      transferredAt: history.transferredAt,
      photo: photo,
      entries: List.unmodifiable(entries),
    );
  }

  static AnimalEntity animal(
    AnimalEntity card,
    AnimalOwnershipHistory history, {
    bool includeEntries = true,
  }) {
    final snapshots =
        history.entries?.where((entry) => entry.kind == 'ANIMAL') ??
        const <HistoricalEntry>[];
    if (snapshots.isEmpty) {
      throw const FormatException(
        'No se encontró la información del animal en el expediente.',
      );
    }
    final data = snapshots.first.data;
    return AnimalDataModel.fromJson({
      ...data, 'id': card.id, 'name': data['name'] ?? card.name,
      'species': data['species'] ?? card.species,
      'sex': data['sex'] ?? card.sex,
      'code': data['code'] ?? card.code,
      'transferStatus': 'TRANSFERRED',
      'readOnly': true,
      // The old owner's picture is obtained using its published file IDs.
      'profilePictureUrl': null,
    }, historicalContext: includeEntries ? history : history.withoutEntries());
  }

  static List<MedicalDocumentEntity> documents(
    AnimalOwnershipHistory history, {
    MedicalDocumentCategory? category,
  }) {
    return [
          for (final entry in history.entries ?? const <HistoricalEntry>[])
            if (entry.kind == 'MEDICAL_DOCUMENT') _document(entry, history),
        ]
        .where(
          (document) => category == null || document.finalCategory == category,
        )
        .toList(growable: false);
  }

  static MedicalDocumentEntity _document(
    HistoricalEntry entry,
    AnimalOwnershipHistory history,
  ) {
    final original = entry.media.where(
      (file) =>
          file.path == 'originalFile' ||
          file.path == 'originalFileUrl' ||
          file.path == 'storageKey',
    );
    final file = entry.media.length == 1
        ? entry.media.single
        : original.firstOrNull;
    return MedicalDocumentModel.fromJson(
      {
        ...entry.data,
        'id': entry.data['id'] ?? entry.data['_id'] ?? entry.entryId,
        'status': entry.data['status'] ?? 'ACCEPTED',
        'canReplace': false,
      },
      readOnly: true,
      historicalFile: file == null ? null : history.file(entry, file),
    );
  }

  static List<DiaryEntryEntity> diary(AnimalOwnershipHistory history) => [
    for (final entry in history.entries ?? const <HistoricalEntry>[])
      if (entry.kind == 'DIARY_ENTRY' || entry.kind == 'DIARY')
        _diaryEntry(entry, history),
  ];

  static DiaryEntryEntity _diaryEntry(
    HistoricalEntry entry,
    AnimalOwnershipHistory history,
  ) {
    final note = DiaryEntryModel.fromJson({
      ...entry.data,
      'id': entry.data['id'] ?? entry.data['_id'] ?? entry.entryId,
    });
    final used = <String>{};
    final attachments = <DiaryAttachmentEntity>[];
    for (var index = 0; index < note.attachments.length; index++) {
      final attachment = note.attachments[index];
      final matches = entry.media.where(
        (file) =>
            file.fileId == attachment.id ||
            file.path == 'attachments.$index.url' ||
            file.path == 'attachments[$index].url' ||
            file.path == '/attachments/$index/url',
      );
      final file =
          matches.firstOrNull ??
          (entry.media.length == 1 && note.attachments.length == 1
              ? entry.media.single
              : null);
      if (file != null) used.add(file.fileId);
      attachments.add(
        DiaryAttachmentEntity(
          id: attachment.id,
          fileName: attachment.fileName,
          fileType: attachment.fileType,
          mimeType: attachment.mimeType,
          url: '',
          size: attachment.size,
          createdAt: attachment.createdAt,
          historicalFile: file == null ? null : history.file(entry, file),
        ),
      );
    }
    for (final file in entry.media.where(
      (file) => !used.contains(file.fileId),
    )) {
      attachments.add(
        DiaryAttachmentEntity(
          id: file.fileId,
          fileName: 'Adjunto ${attachments.length + 1}',
          fileType: 'file',
          mimeType: 'application/octet-stream',
          url: '',
          size: 0,
          createdAt: note.createdAt,
          historicalFile: history.file(entry, file),
        ),
      );
    }
    return DiaryEntryEntity(
      id: note.id,
      animalId: note.animalId,
      title: note.title,
      content: note.content,
      date: note.date,
      attachments: attachments,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    );
  }
}
