/// Maps backend error codes and messages to user-friendly messages.
///
/// This class sanitizes error messages to prevent leaking sensitive backend information
/// to end users while maintaining helpful error feedback.
class ErrorMapper {
  /// Maps error responses to user-friendly messages.
  ///
  /// [error] can be a Map containing error code/message, or a dynamic value.
  /// Returns a sanitized, user-friendly error message.
  static String mapToUserMessage(dynamic error) {
    // Handle Map responses with error codes
    if (error is Map<String, dynamic>) {
      final code = error['code'] as String?;
      if (code != null && _errorCodeMessages.containsKey(code)) {
        return _errorCodeMessages[code]!;
      }

      // Fallback to known safe message keys
      final message = error['message'] as String?;
      if (message != null && _safeMessages.contains(message)) {
        return message;
      }
    }

    // Default fallback
    return 'Error del servidor. Por favor, intenta nuevamente.';
  }

  /// Known error codes mapped to user-friendly messages
  static const Map<String, String> _errorCodeMessages = {
    'INVALID_CREDENTIALS': 'Credenciales inválidas',
    'USER_NOT_FOUND': 'Usuario no encontrado',
    'USER_NOT_VERIFIED': 'Usuario no verificado',
    'INVALID_TOKEN': 'Sesión expirada. Por favor, inicia sesión nuevamente.',
    'NETWORK_ERROR': 'Error de conexión. Verifica tu internet.',
    'VALIDATION_ERROR': 'Datos inválidos. Por favor, verifica la información.',
    'DUPLICATE_USER': 'Este usuario ya existe',
    'DUPLICATE_EMAIL': 'Este correo ya está registrado',
    'DUPLICATE_PHONE': 'Este teléfono ya está registrado',
    'INVALID_CODE': 'Código de verificación inválido o expirado',
  };

  /// Messages that are safe to show directly to users
  static const Set<String> _safeMessages = {
    'Credenciales inválidas',
    'Usuario no encontrado',
    'Código de verificación inválido',
  };
}
