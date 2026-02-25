class ErrorMapper {
  static String mapToUserMessage(dynamic error) {
    if (error is Map<String, dynamic>) {
      final code = error['code'] as String?;
      if (code != null && _errorCodeMessages.containsKey(code)) {
        return _errorCodeMessages[code]!;
      }

      final message = error['message'] as String?;
      if (message != null && _safeMessages.contains(message)) {
        return message;
      }
    }

    return 'Error del servidor. Por favor, intenta nuevamente.';
  }

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
    'INVALID_CODE': 'Código incorrecto. Intente nuevamente.',
  };

  static const Set<String> _safeMessages = {
    'Credenciales inválidas',
    'Usuario no encontrado',
    'Código incorrecto. Intente nuevamente.',
  };
}
