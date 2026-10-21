import 'dart:convert';

import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingMedicalDocumentFlow {
  final String documentId;
  final List<String> animalIds;
  final DateTime startedAt;
  final MedicalDocumentCategory? requestedCategory;

  const PendingMedicalDocumentFlow({
    required this.documentId,
    required this.animalIds,
    required this.startedAt,
    this.requestedCategory,
  });
}

abstract interface class PendingMedicalDocumentLocalDataSource {
  Future<void> save(PendingMedicalDocumentFlow flow);
  PendingMedicalDocumentFlow? read();
  Future<void> clear();
}

class PendingMedicalDocumentLocalDataSourceImpl
    implements PendingMedicalDocumentLocalDataSource {
  static const _storageKey = 'PENDING_MEDICAL_DOCUMENT_FLOW';
  final SharedPreferences sharedPreferences;

  const PendingMedicalDocumentLocalDataSourceImpl({
    required this.sharedPreferences,
  });

  @override
  Future<void> save(PendingMedicalDocumentFlow flow) async {
    await sharedPreferences.setString(
      _storageKey,
      jsonEncode({
        'documentId': flow.documentId,
        'animalIds': flow.animalIds,
        'startedAt': flow.startedAt.toIso8601String(),
        if (flow.requestedCategory != null)
          'requestedCategory': flow.requestedCategory!.wireValue,
      }),
    );
  }

  @override
  PendingMedicalDocumentFlow? read() {
    final stored = sharedPreferences.getString(_storageKey);
    if (stored == null) return null;
    try {
      final json = jsonDecode(stored) as Map<String, dynamic>;
      final documentId = json['documentId']?.toString() ?? '';
      final startedAt = DateTime.tryParse(json['startedAt']?.toString() ?? '');
      final animalIds = (json['animalIds'] as List<dynamic>? ?? const [])
          .map((id) => id.toString())
          .where((id) => id.trim().isNotEmpty)
          .toList(growable: false);
      if (documentId.isEmpty ||
          startedAt == null ||
          animalIds.isEmpty ||
          animalIds.toSet().length != animalIds.length) {
        return null;
      }
      return PendingMedicalDocumentFlow(
        documentId: documentId,
        animalIds: animalIds,
        startedAt: startedAt,
        requestedCategory: MedicalDocumentCategory.tryParse(
          json['requestedCategory'],
        ),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clear() => sharedPreferences.remove(_storageKey);
}
