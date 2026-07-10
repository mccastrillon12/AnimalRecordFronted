import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';

class DiaryAttachmentModel extends DiaryAttachmentEntity {
  const DiaryAttachmentModel({
    required super.id,
    required super.fileName,
    required super.fileType,
    required super.mimeType,
    required super.url,
    required super.size,
    required super.createdAt,
  });

  factory DiaryAttachmentModel.fromJson(Map<String, dynamic> json) {
    return DiaryAttachmentModel(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileType: json['fileType'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? '',
      url: json['url'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class DiaryEntryModel extends DiaryEntryEntity {
  const DiaryEntryModel({
    required super.id,
    required super.animalId,
    required super.title,
    required super.content,
    required super.date,
    required super.attachments,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DiaryEntryModel.fromJson(Map<String, dynamic> json) {
    final attachmentsList = (json['attachments'] as List<dynamic>?)
            ?.map((a) => DiaryAttachmentModel.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [];

    return DiaryEntryModel(
      id: json['id'] as String? ?? '',
      animalId: json['animalId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      date: json['date'] as String? ?? '',
      attachments: attachmentsList,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
