import 'dart:convert';

String normalizeMedicalDocumentFileName(Object? value) {
  var normalized = value?.toString() ?? '';

  if (normalized.contains('Ã') ||
      normalized.contains('Â') ||
      normalized.contains('Ì')) {
    try {
      final decoded = utf8.decode(latin1.encode(normalized));
      if (!decoded.contains('\uFFFD')) normalized = decoded;
    } catch (_) {
      // Keep the backend value if it is not a recoverable UTF-8/Latin-1 mix.
    }
  }

  const composedCharacters = <String, String>{
    'a\u0301': 'á',
    'e\u0301': 'é',
    'i\u0301': 'í',
    'o\u0301': 'ó',
    'u\u0301': 'ú',
    'A\u0301': 'Á',
    'E\u0301': 'É',
    'I\u0301': 'Í',
    'O\u0301': 'Ó',
    'U\u0301': 'Ú',
    'n\u0303': 'ñ',
    'N\u0303': 'Ñ',
    'u\u0308': 'ü',
    'U\u0308': 'Ü',
  };
  for (final entry in composedCharacters.entries) {
    normalized = normalized.replaceAll(entry.key, entry.value);
  }

  return normalized
      .replaceAll('Fo\uFFFDrmula', 'Fórmula')
      .replaceAll('fo\uFFFDrmula', 'fórmula')
      .replaceAll('Me\uFFFDdica', 'Médica')
      .replaceAll('me\uFFFDdica', 'médica');
}
