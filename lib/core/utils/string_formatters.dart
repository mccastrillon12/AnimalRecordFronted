/// Utilidad para formateo de strings
class StringFormatters {
  /// Formatea un nombre capitalizando la primera letra de cada palabra
  /// y convirtiendo el resto a minúsculas
  ///
  /// Ejemplo: "JUAN PÉREZ" -> "Juan Pérez"
  static String formatName(String name) {
    if (name.isEmpty) return '';

    final parts = name.trim().split(RegExp(r'\s+'));
    final formattedParts = parts.map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    });

    return formattedParts.join(' ');
  }
}
