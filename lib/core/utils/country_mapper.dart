/// Utility class for mapping between country codes and country names.
///
/// This class provides bidirectional mappings to avoid hardcoded strings
/// throughout the application and maintain consistency in country data.
///
/// Example:
/// ```dart
/// String name = CountryMapper.getName('COP'); // Returns 'Colombia'
/// String code = CountryMapper.getCode('México'); // Returns 'MEX'
/// ```
class CountryMapper {
  /// Private constructor to prevent instantiation
  CountryMapper._();

  /// Mapping from country code to country name
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

  /// Mapping from country name to country code
  static final Map<String, String> _nameToCode = {
    for (var entry in _codeToName.entries) entry.value: entry.key,
  };

  /// Gets the country name for a given country code.
  ///
  /// Returns 'Colombia' as default if the code is not found.
  ///
  /// Example:
  /// ```dart
  /// String name = CountryMapper.getName('COP'); // Returns 'Colombia'
  /// String unknown = CountryMapper.getName('XYZ'); // Returns 'Colombia' (default)
  /// ```
  static String getName(String code) {
    return _codeToName[code] ?? 'Colombia';
  }

  /// Gets the country code for a given country name.
  ///
  /// Returns 'COP' as default if the name is not found.
  ///
  /// Example:
  /// ```dart
  /// String code = CountryMapper.getCode('México'); // Returns 'MEX'
  /// String unknown = CountryMapper.getCode('Unknown'); // Returns 'COP' (default)
  /// ```
  static String getCode(String name) {
    return _nameToCode[name] ?? 'COP';
  }

  /// Gets all available country codes
  static List<String> get allCodes => _codeToName.keys.toList();

  /// Gets all available country names
  static List<String> get allNames => _codeToName.values.toList();

  /// Checks if a country code exists in the mapping
  static bool hasCode(String code) => _codeToName.containsKey(code);

  /// Checks if a country name exists in the mapping
  static bool hasName(String name) => _nameToCode.containsKey(name);
}
