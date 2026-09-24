/// Presentation-only rules shared by every medical-document projection.
///
/// The backend payload remains untouched. These helpers only decide what can
/// be rendered and how scalar values are presented to the user.
bool isMedicalDocumentTechnicalKey(
  String key,
  Set<String> hiddenTechnicalKeys,
) {
  final normalized = _normalizedKey(key);
  if (normalized.isEmpty) return false;

  if (hiddenTechnicalKeys.any(
    (hiddenKey) => _normalizedKey(hiddenKey) == normalized,
  )) {
    return true;
  }

  if (const {
    'warning',
    'warnings',
    'advertencia',
    'advertencias',
  }.contains(normalized)) {
    return true;
  }

  if (normalized.contains('confidence') || normalized.contains('confianza')) {
    return true;
  }

  final isClassification =
      normalized.contains('classification') ||
      normalized.contains('clasificacion');
  final isScore =
      normalized.contains('score') ||
      normalized.contains('probability') ||
      normalized.contains('probabilidad') ||
      normalized.contains('puntuacion');
  return isClassification && isScore;
}

bool isMedicalDocumentTechnicalPath(
  String path,
  Set<String> hiddenTechnicalKeys,
) => path
    .split('.')
    .any(
      (segment) => isMedicalDocumentTechnicalKey(segment, hiddenTechnicalKeys),
    );

String medicalDocumentDisplayValue(
  Object? value, {
  Set<String> hiddenTechnicalKeys = const {},
}) {
  if (value == null) return '';
  if (value is Iterable) {
    return value
        .where((item) => !_isEmpty(item))
        .map(
          (item) => medicalDocumentDisplayValue(
            item,
            hiddenTechnicalKeys: hiddenTechnicalKeys,
          ),
        )
        .where((item) => item.isNotEmpty)
        .join(', ');
  }
  if (value is Map) {
    return value.entries
        .where(
          (entry) =>
              !isMedicalDocumentTechnicalKey(
                entry.key.toString(),
                hiddenTechnicalKeys,
              ) &&
              !_isEmpty(entry.value),
        )
        .map(
          (entry) => medicalDocumentDisplayValue(
            entry.value,
            hiddenTechnicalKeys: hiddenTechnicalKeys,
          ),
        )
        .where((item) => item.isNotEmpty)
        .join(', ');
  }

  return value.toString().trim();
}

String _normalizedKey(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('ó', 'o')
    .replaceAll('í', 'i')
    .replaceAll(RegExp(r'[^a-z0-9]'), '');

bool _isEmpty(Object? value) {
  if (value == null) return true;
  if (value is String) return value.trim().isEmpty;
  if (value is Iterable) return value.isEmpty;
  if (value is Map) return value.isEmpty;
  return false;
}
