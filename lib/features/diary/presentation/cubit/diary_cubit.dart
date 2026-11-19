import 'package:animal_record/features/home/domain/entities/animal_ownership.dart';
import 'package:animal_record/features/home/domain/usecases/animal_history_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/diary/domain/entities/local_attachment.dart';
import 'package:animal_record/features/diary/domain/usecases/get_diary_entries_usecase.dart';
import 'package:animal_record/features/diary/domain/usecases/create_diary_entry_usecase.dart';
import 'package:animal_record/features/diary/domain/usecases/update_diary_entry_usecase.dart';
import 'package:animal_record/features/diary/domain/usecases/delete_diary_entry_usecase.dart';
import 'package:animal_record/features/diary/domain/usecases/delete_attachment_usecase.dart';
import 'package:animal_record/features/diary/domain/usecases/upload_diary_attachment_usecase.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_state.dart';

class DiaryCubit extends Cubit<DiaryState> {
  final GetDiaryEntriesUseCase getDiaryEntriesUseCase;
  final CreateDiaryEntryUseCase createDiaryEntryUseCase;
  final UpdateDiaryEntryUseCase updateDiaryEntryUseCase;
  final DeleteDiaryEntryUseCase deleteDiaryEntryUseCase;
  final DeleteAttachmentUseCase deleteAttachmentUseCase;
  final UploadDiaryAttachmentUseCase uploadDiaryAttachmentUseCase;

  List<DiaryEntryEntity> _entries = [];
  final GetHistoricalDiaryUseCase? historicalDiaryUseCase;
  AnimalOwnershipHistory? _history;
  bool _readOnly = false;
  bool _historical = false;

  DiaryCubit({
    required this.getDiaryEntriesUseCase,
    this.historicalDiaryUseCase,
    required this.createDiaryEntryUseCase,
    required this.updateDiaryEntryUseCase,
    required this.deleteDiaryEntryUseCase,
    required this.deleteAttachmentUseCase,
    required this.uploadDiaryAttachmentUseCase,
  }) : super(DiaryInitial());

  List<DiaryEntryEntity> get entries => _entries;

  // ── Fetch all entries ─────────────────────────────────────────

  Future<void> getDiaryEntries(
    String animalId, {
    AnimalOwnershipHistory? history,
    bool readOnly = false,
    bool historical = false,
  }) async {
    _history = history;
    _readOnly = readOnly || historical || history != null;
    _historical = historical || history != null;
    _entries = [];
    emit(DiaryLoading());
    await _readEntries(animalId);
  }

  /// Refresh the same source without replacing the current screen with a spinner.
  Future<void> refreshDiaryEntries(String animalId) => _readEntries(animalId);

  Future<void> _readEntries(String animalId) async {
    if (_historical && _history == null) {
      if (!isClosed) {
        emit(
          DiaryError(
            'No se encontró la publicación del expediente.',
            existingEntries: const [],
          ),
        );
      }
      return;
    }
    final history = _history;
    if (history != null) {
      try {
        final reader = historicalDiaryUseCase;
        if (reader == null) throw StateError('Falta el lector de histórico.');
        final entries = await reader(history);
        if (isClosed) return;
        _entries = entries;
        emit(DiaryLoaded(_entries));
      } catch (_) {
        if (!isClosed) {
          emit(
            DiaryError(
              'No se pudo cargar el diario.',
              existingEntries: _entries,
            ),
          );
        }
      }
      return;
    }
    final result = await getDiaryEntriesUseCase(animalId);
    if (isClosed) return;
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
    if (_readOnly) {
      emit(
        DiaryError('El diario es de solo lectura.', existingEntries: _entries),
      );
      return;
    }
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
      final createError = createResult.fold((failure) => failure.message, (
        entry,
      ) {
        createdEntry = entry;
        return null;
      });

      if (createError != null || createdEntry == null) {
        emit(
          DiaryError(
            createError ?? 'Error al crear la nota.',
            existingEntries: _entries,
          ),
        );
        return;
      }

      // Step 2 & 3: Upload each attachment
      for (final attachment in attachments) {
        final uploadResult = await uploadDiaryAttachmentUseCase(
          animalId: animalId,
          entryId: createdEntry!.id,
          attachment: attachment,
        );
        final uploadError = uploadResult.fold(
          (failure) => failure.message,
          (_) => null,
        );
        if (uploadError != null) {
          emit(DiaryError(uploadError, existingEntries: _entries));
          return;
        }
      }

      // Re-fetch entries to get consistent state
      final fetchResult = await getDiaryEntriesUseCase(animalId);
      fetchResult.fold(
        (_) => _entries = [createdEntry!, ..._entries],
        (entries) => _entries = entries,
      );

      emit(DiaryEntrySaved(createdEntry!, allEntries: _entries));
    } catch (e) {
      emit(
        DiaryError(
          'Error inesperado: ${e.toString()}.',
          existingEntries: _entries,
        ),
      );
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
    if (_readOnly) {
      emit(
        DiaryError('El diario es de solo lectura.', existingEntries: _entries),
      );
      return;
    }
    emit(DiaryEntrySaving(existingEntries: _entries));

    try {
      final updateResult = await updateDiaryEntryUseCase(
        animalId: animalId,
        entryId: entryId,
        title: title,
        content: content,
      );

      DiaryEntryEntity? updatedEntry;
      final updateError = updateResult.fold((failure) => failure.message, (
        entry,
      ) {
        updatedEntry = entry;
        return null;
      });

      if (updateError != null || updatedEntry == null) {
        emit(
          DiaryError(
            updateError ?? 'Error al actualizar la nota.',
            existingEntries: _entries,
          ),
        );
        return;
      }

      // Upload any new attachments added during edit
      for (final attachment in newAttachments) {
        final uploadResult = await uploadDiaryAttachmentUseCase(
          animalId: animalId,
          entryId: entryId,
          attachment: attachment,
        );
        final uploadError = uploadResult.fold(
          (failure) => failure.message,
          (_) => null,
        );
        if (uploadError != null) {
          emit(DiaryError(uploadError, existingEntries: _entries));
          return;
        }
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
      fetchResult.fold((_) {
        _entries = _entries
            .map((e) => e.id == entryId ? updatedEntry! : e)
            .toList();
      }, (entries) => _entries = entries);

      emit(DiaryEntryUpdated(updatedEntry!, allEntries: _entries));
    } catch (e) {
      emit(
        DiaryError(
          'Error inesperado: ${e.toString()}.',
          existingEntries: _entries,
        ),
      );
    }
  }

  // ── Delete entry ──────────────────────────────────────────────

  Future<void> deleteDiaryEntry({
    required String animalId,
    required String entryId,
  }) async {
    if (_readOnly) {
      emit(
        DiaryError('El diario es de solo lectura.', existingEntries: _entries),
      );
      return;
    }
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

  /// Reset to loaded state.
  void resetToLoaded() {
    emit(DiaryLoaded(_entries));
  }
}
