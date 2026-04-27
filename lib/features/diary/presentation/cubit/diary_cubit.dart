import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:animal_record/core/services/s3_upload_service.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/diary/domain/usecases/get_diary_entries_usecase.dart';
import 'package:animal_record/features/diary/domain/usecases/create_diary_entry_usecase.dart';
import 'package:animal_record/features/diary/domain/usecases/update_diary_entry_usecase.dart';
import 'package:animal_record/features/diary/domain/usecases/delete_diary_entry_usecase.dart';
import 'package:animal_record/features/diary/domain/usecases/get_attachment_upload_url_usecase.dart';
import 'package:animal_record/features/diary/domain/usecases/confirm_attachment_usecase.dart';
import 'package:animal_record/features/diary/domain/usecases/delete_attachment_usecase.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_state.dart';

/// Holds local attachment info before uploading.
class LocalAttachment {
  final String path;
  final String fileName;
  final String mimeType;
  final String fileType; // 'image' | 'audio'
  final int size;

  LocalAttachment({
    required this.path,
    required this.fileName,
    required this.mimeType,
    required this.fileType,
    required this.size,
  });
}

class DiaryCubit extends Cubit<DiaryState> {
  final GetDiaryEntriesUseCase getDiaryEntriesUseCase;
  final CreateDiaryEntryUseCase createDiaryEntryUseCase;
  final UpdateDiaryEntryUseCase updateDiaryEntryUseCase;
  final DeleteDiaryEntryUseCase deleteDiaryEntryUseCase;
  final GetAttachmentUploadUrlUseCase getAttachmentUploadUrlUseCase;
  final ConfirmAttachmentUseCase confirmAttachmentUseCase;
  final DeleteAttachmentUseCase deleteAttachmentUseCase;
  final S3UploadService s3UploadService;

  List<DiaryEntryEntity> _entries = [];

  DiaryCubit({
    required this.getDiaryEntriesUseCase,
    required this.createDiaryEntryUseCase,
    required this.updateDiaryEntryUseCase,
    required this.deleteDiaryEntryUseCase,
    required this.getAttachmentUploadUrlUseCase,
    required this.confirmAttachmentUseCase,
    required this.deleteAttachmentUseCase,
    required this.s3UploadService,
  }) : super(DiaryInitial());

  List<DiaryEntryEntity> get entries => _entries;

  // ── Fetch all entries ─────────────────────────────────────────

  Future<void> getDiaryEntries(String animalId) async {
    emit(DiaryLoading());

    final result = await getDiaryEntriesUseCase(animalId);

    result.fold(
      (failure) => emit(DiaryError(failure.message, existingEntries: _entries)),
      (entries) {
        _entries = entries;
        emit(DiaryLoaded(entries));
      },
    );
  }

  // ── Create entry + upload attachments ─────────────────────────

  Future<void> createDiaryEntry({
    required String animalId,
    required String title,
    required String content,
    required String date,
    required List<LocalAttachment> attachments,
  }) async {
    emit(DiaryEntrySaving(existingEntries: _entries));

    try {
      // Step 1: Create entry (text only)
      final createResult = await createDiaryEntryUseCase(
        animalId: animalId,
        title: title,
        content: content,
        date: date,
      );

      DiaryEntryEntity? createdEntry;
      final createError = createResult.fold(
        (failure) => failure.message,
        (entry) {
          createdEntry = entry;
          return null;
        },
      );

      if (createError != null || createdEntry == null) {
        emit(DiaryError(
          createError ?? 'Error al crear la nota',
          existingEntries: _entries,
        ));
        return;
      }

      // Step 2 & 3: Upload each attachment
      for (final attachment in attachments) {
        await _uploadAttachment(
          animalId: animalId,
          entryId: createdEntry!.id,
          attachment: attachment,
        );
      }

      // Re-fetch entries to get consistent state
      final fetchResult = await getDiaryEntriesUseCase(animalId);
      fetchResult.fold(
        (_) => _entries = [createdEntry!, ..._entries],
        (entries) => _entries = entries,
      );

      emit(DiaryEntrySaved(createdEntry!, allEntries: _entries));
    } catch (e) {
      emit(DiaryError(
        'Error inesperado: ${e.toString()}',
        existingEntries: _entries,
      ));
    }
  }

  // ── Update entry (title + content only) ───────────────────────

  Future<void> updateDiaryEntry({
    required String animalId,
    required String entryId,
    required String title,
    required String content,
    List<LocalAttachment> newAttachments = const [],
    List<String> deletedAttachmentIds = const [],
  }) async {
    emit(DiaryEntrySaving(existingEntries: _entries));

    try {
      final updateResult = await updateDiaryEntryUseCase(
        animalId: animalId,
        entryId: entryId,
        title: title,
        content: content,
      );

      DiaryEntryEntity? updatedEntry;
      final updateError = updateResult.fold(
        (failure) => failure.message,
        (entry) {
          updatedEntry = entry;
          return null;
        },
      );

      if (updateError != null || updatedEntry == null) {
        emit(DiaryError(
          updateError ?? 'Error al actualizar la nota',
          existingEntries: _entries,
        ));
        return;
      }

      // Upload any new attachments added during edit
      for (final attachment in newAttachments) {
        await _uploadAttachment(
          animalId: animalId,
          entryId: entryId,
          attachment: attachment,
        );
      }

      // Delete attachments marked for deletion
      for (final attachmentId in deletedAttachmentIds) {
        try {
          await deleteAttachmentUseCase(
            animalId: animalId,
            entryId: entryId,
            attachmentId: attachmentId,
          );
        } catch (_) {
          // If a deletion fails, we can log it but shouldn't stop the whole update process
        }
      }

      // Re-fetch entries
      final fetchResult = await getDiaryEntriesUseCase(animalId);
      fetchResult.fold(
        (_) {
          _entries = _entries
              .map((e) => e.id == entryId ? updatedEntry! : e)
              .toList();
        },
        (entries) => _entries = entries,
      );

      emit(DiaryEntryUpdated(updatedEntry!, allEntries: _entries));
    } catch (e) {
      emit(DiaryError(
        'Error inesperado: ${e.toString()}',
        existingEntries: _entries,
      ));
    }
  }

  // ── Delete entry ──────────────────────────────────────────────

  Future<void> deleteDiaryEntry({
    required String animalId,
    required String entryId,
  }) async {
    emit(DiaryEntrySaving(existingEntries: _entries));

    final result = await deleteDiaryEntryUseCase(
      animalId: animalId,
      entryId: entryId,
    );

    result.fold(
      (failure) => emit(DiaryError(failure.message, existingEntries: _entries)),
      (_) {
        _entries = _entries.where((e) => e.id != entryId).toList();
        emit(DiaryEntryDeleted(allEntries: _entries));
      },
    );
  }

  // ── Upload a single attachment ────────────────────────────────

  Future<void> _uploadAttachment({
    required String animalId,
    required String entryId,
    required LocalAttachment attachment,
  }) async {
    Uint8List bytes;
    if (attachment.fileType == 'image') {
      final compressed = await FlutterImageCompress.compressWithFile(
        attachment.path,
        minWidth: 1920,
        minHeight: 1080,
        quality: 85,
        format: CompressFormat.jpeg,
      );
      bytes = compressed ?? await File(attachment.path).readAsBytes();
    } else {
      bytes = await File(attachment.path).readAsBytes();
    }

    final mimeType = attachment.fileType == 'image'
        ? 'image/jpeg'
        : attachment.mimeType;
    final fileSize = bytes.length;

    final urlResult = await getAttachmentUploadUrlUseCase(
      animalId: animalId,
      entryId: entryId,
      mimeType: mimeType,
      fileSize: fileSize,
    );

    await urlResult.fold(
      (_) async {},
      (urlData) async {
        final uploadUrl = urlData['uploadUrl'] as String?;
        final finalUrl = urlData['finalUrl'] as String?;
        final attachmentId = urlData['attachmentId'] as String?;

        if (uploadUrl == null || finalUrl == null || attachmentId == null) return;

        await s3UploadService.uploadFileToS3(
          presignedUrl: uploadUrl,
          bytes: bytes,
          mimeType: mimeType,
        );

        await confirmAttachmentUseCase(
          animalId: animalId,
          entryId: entryId,
          attachmentId: attachmentId,
          finalUrl: finalUrl,
          fileName: attachment.fileName,
          mimeType: mimeType,
          size: fileSize,
        );
      },
    );
  }

  /// Reset to loaded state.
  void resetToLoaded() {
    emit(DiaryLoaded(_entries));
  }
}
