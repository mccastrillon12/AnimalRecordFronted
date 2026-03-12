class CountryConstants {
  /// Lista de indicativos de país (sin el '+') soportados por la aplicación.
  /// Se deben agregar aquí a medida que se habiliten nuevos países.
  static const List<String> supportedDialCodes = [
    '57', // Colombia
    '1',  // Estados Unidos / Canadá
  ];

  /// Limpia un número de teléfono crudo (ej. desde la BD) quitando todos los 
  /// caracteres no numéricos y luego removiendo el indicativo si este se encuentra
  /// en la lista de indicativos soportados.
  static String stripDialCode(String rawPhone) {
    String cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    
    for (String code in supportedDialCodes) {
      if (cleanPhone.startsWith(code)) {
        return cleanPhone.substring(code.length);
      }
    }
    
    return cleanPhone;
  }
}
