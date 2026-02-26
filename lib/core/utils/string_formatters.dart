class StringFormatters {
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
