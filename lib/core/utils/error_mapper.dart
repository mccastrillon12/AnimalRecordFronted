class ErrorMapper {
  static String mapTransferMessage(int? statusCode, dynamic data) {
    final mapped = mapToUserMessage(data);
    if (mapped != 'Error del servidor. Por favor, intenta nuevamente.') {
      return mapped;
    }
    return switch (statusCode) {
      null =>
        'No se pudo confirmar la respuesta. Revisa tu conexión y consulta el estado de la operación.',
      400 =>
        'Datos de transferencia inválidos (400). Revisa los campos y el motivo.',
      401 => 'La sesión expiró (401). Inicia sesión nuevamente.',
      403 => 'Esta cuenta no tiene acceso a este recurso (403).',
      404 => 'El recurso no está disponible o no está publicado (404).',
      409 =>
        'La operación presenta un conflicto (409). Actualiza el estado de la solicitud.',
      429 => 'Demasiados intentos (429). Espera antes de volver a intentarlo.',
      502 =>
        'Falló el almacenamiento o transporte de archivos (502). Consulta el estado antes de reintentar.',
      503 =>
        'El servicio no pudo confirmar la operación (503). Consulta su estado antes de reintentar.',
      _ => 'No se pudo completar la operación ($statusCode).',
    };
  }

  static String mapToUserMessage(dynamic error) {
    if (error is Map<String, dynamic>) {
      final code = error['code'];
      if (code is String && _errorCodeMessages.containsKey(code)) {
        return _errorCodeMessages[code]!;
      }

      final message = error['message'];
      if (message is String && _safeMessages.contains(message)) {
        return message;
      }
    }

    return 'Error del servidor. Por favor, intenta nuevamente.';
  }

  static const Map<String, String> _errorCodeMessages = {
    'INVALID_CREDENTIALS': 'Credenciales inválidas.',
    'USER_NOT_FOUND': 'Usuario no encontrado.',
    'USER_NOT_VERIFIED': 'Usuario no verificado.',
    'INVALID_TOKEN': 'Sesión expirada. Por favor, inicia sesión nuevamente.',
    'NETWORK_ERROR': 'Error de conexión. Verifica tu internet.',
    'VALIDATION_ERROR': 'Datos inválidos. Por favor, verifica la información.',
    'DUPLICATE_USER': 'Este usuario ya existe.',
    'DUPLICATE_EMAIL': 'Este correo ya está registrado.',
    'DUPLICATE_PHONE': 'Este teléfono ya está registrado.',
    'INVALID_CODE': 'Código incorrecto. Intente nuevamente.',
  };

  static const Set<String> _safeMessages = {
    'Credenciales inválidas',
    'Usuario no encontrado',
    'Código incorrecto. Intente nuevamente.',
  };
}
