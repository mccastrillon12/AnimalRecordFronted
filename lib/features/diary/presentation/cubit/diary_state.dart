import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';

abstract class DiaryState {}

class DiaryInitial extends DiaryState {}

class DiaryLoading extends DiaryState {}

class DiaryLoaded extends DiaryState {
  final List<DiaryEntryEntity> entries;
  DiaryLoaded(this.entries);
}

class DiaryEntrySaving extends DiaryState {
  final List<DiaryEntryEntity> existingEntries;
  DiaryEntrySaving({this.existingEntries = const []});
}

class DiaryEntrySaved extends DiaryState {
  final DiaryEntryEntity entry;
  final List<DiaryEntryEntity> allEntries;
  DiaryEntrySaved(this.entry, {required this.allEntries});
}

class DiaryEntryUpdated extends DiaryState {
  final DiaryEntryEntity entry;
  final List<DiaryEntryEntity> allEntries;
  DiaryEntryUpdated(this.entry, {required this.allEntries});
}

class DiaryEntryDeleted extends DiaryState {
  final List<DiaryEntryEntity> allEntries;
  DiaryEntryDeleted({required this.allEntries});
}

class DiaryError extends DiaryState {
  final String message;
  final List<DiaryEntryEntity> existingEntries;
  DiaryError(this.message, {this.existingEntries = const []});
}
