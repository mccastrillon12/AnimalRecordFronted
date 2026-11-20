/// Shared validation for transfer and rejection comments. No transport or UI.
abstract final class TransferCommentPolicy {
  static const maxLength = 500;

  static bool isValid(String value) {
    final comment = value.trim();
    return comment.isNotEmpty && comment.runes.length <= maxLength;
  }

  static String? normalize(String code, String? value) {
    if (code != 'OTHER') {
      if (value != null) {
        throw const FormatException('Este motivo no admite comentario.');
      }
      return null;
    }
    if (value == null || !isValid(value)) {
      throw const FormatException(
        'Explica el motivo con entre 1 y 500 caracteres.',
      );
    }
    return value.trim();
  }
}
