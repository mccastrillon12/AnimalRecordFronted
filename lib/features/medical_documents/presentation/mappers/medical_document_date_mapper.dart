DateTime? parseMedicalDocumentDate(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return null;

  final isoDate = DateTime.tryParse(raw);
  if (isoDate != null) return isoDate;

  final normalized = _normalize(raw);
  final localizedMatch = RegExp(
    r'(\d{1,2})\s+de\s+([a-z]+)\s+de\s+(\d{4})'
    r'(?:.*?(\d{1,2}):(\d{2})\s*([ap])\.?\s*m\.?)?',
  ).firstMatch(normalized);
  if (localizedMatch != null) {
    final month = _months[localizedMatch.group(2)];
    if (month != null) {
      var hour = int.tryParse(localizedMatch.group(4) ?? '') ?? 0;
      final minute = int.tryParse(localizedMatch.group(5) ?? '') ?? 0;
      final period = localizedMatch.group(6);
      if (period == 'p' && hour < 12) hour += 12;
      if (period == 'a' && hour == 12) hour = 0;
      return DateTime(
        int.parse(localizedMatch.group(3)!),
        month,
        int.parse(localizedMatch.group(1)!),
        hour,
        minute,
      );
    }
  }

  final numericMatch = RegExp(
    r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$',
  ).firstMatch(normalized);
  if (numericMatch != null) {
    return DateTime(
      int.parse(numericMatch.group(3)!),
      int.parse(numericMatch.group(2)!),
      int.parse(numericMatch.group(1)!),
    );
  }
  return null;
}

String displayMedicalDocumentDate(String? value) {
  final parsed = parseMedicalDocumentDate(value);
  if (parsed == null) return value?.trim() ?? '';
  return formatMedicalDocumentDate(parsed);
}

String formatMedicalDocumentDate(DateTime date) {
  const months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

const _months = {
  'enero': 1,
  'febrero': 2,
  'marzo': 3,
  'abril': 4,
  'mayo': 5,
  'junio': 6,
  'julio': 7,
  'agosto': 8,
  'septiembre': 9,
  'setiembre': 9,
  'octubre': 10,
  'noviembre': 11,
  'diciembre': 12,
};

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
