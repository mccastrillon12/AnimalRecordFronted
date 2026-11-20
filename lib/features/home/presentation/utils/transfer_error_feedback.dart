import 'package:animal_record/core/network/api_exception.dart';
import 'package:animal_record/core/network/transfer_error_diagnostics.dart';

/// UI text is authored locally; server diagnostics only go to the console.
abstract final class TransferErrorFeedback {
  static String message(
    Object error, {
    String fallback = 'No pudimos completar la acción. Inténtalo de nuevo.',
  }) {
    TransferErrorDiagnostics.record(error);
    if (error is! ApiException) return fallback;
    return switch (error.statusCode) {
      401 => 'Tu sesión venció. Inicia sesión nuevamente.',
      403 || 404 => 'Esta información no está disponible para tu cuenta.',
      429 => 'Espera un momento antes de intentarlo de nuevo.',
      _ => fallback,
    };
  }
}
