import 'package:equatable/equatable.dart';

class DiaryAttachmentEntity extends Equatable {
  final String id;
  final String fileName;
  final String fileType;
  final String mimeType;
  final String url;
  final int size;
  final String createdAt;

  const DiaryAttachmentEntity({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.mimeType,
    required this.url,
    required this.size,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, fileName, fileType, mimeType, url, size, createdAt];
}

class DiaryEntryEntity extends Equatable {
  final String id;
  final String animalId;
  final String title;
  final String content;
  final String date;
  final List<DiaryAttachmentEntity> attachments;
  final String createdAt;
  final String updatedAt;

  const DiaryEntryEntity({
    required this.id,
    required this.animalId,
    required this.title,
    required this.content,
    required this.date,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, animalId, title, content, date, attachments, createdAt, updatedAt];
}
