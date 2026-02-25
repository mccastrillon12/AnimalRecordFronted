class CountryMapper {
  CountryMapper._();

  static const Map<String, String> _codeToName = {
    'COP': 'Colombia',
    'USA': 'Estados Unidos',
    'MEX': 'México',
    'ARG': 'Argentina',
    'BRA': 'Brasil',
    'CHL': 'Chile',
    'PER': 'Perú',
    'VEN': 'Venezuela',
    'ECU': 'Ecuador',
    'URY': 'Uruguay',
    'PRY': 'Paraguay',
    'BOL': 'Bolivia',
  };

  static final Map<String, String> _nameToCode = {
    for (var entry in _codeToName.entries) entry.value: entry.key,
  };

  static String getName(String code) {
    return _codeToName[code] ?? 'Colombia';
  }

  static String getCode(String name) {
    return _nameToCode[name] ?? 'COP';
  }

  static List<String> get allCodes => _codeToName.keys.toList();

  static List<String> get allNames => _codeToName.values.toList();

  static bool hasCode(String code) => _codeToName.containsKey(code);

  static bool hasName(String name) => _nameToCode.containsKey(name);
}
