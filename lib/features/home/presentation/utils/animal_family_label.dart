final _animalCodePattern = RegExp(
  r'^AR-([CFBE])[0-9]{3,}$',
  caseSensitive: false,
);

String animalFamilyFromCode(String code) => switch (_animalCodePattern
    .firstMatch(code.trim())
    ?.group(1)
    ?.toUpperCase()) {
  'C' => 'Canino',
  'F' => 'Felino',
  'B' => 'Bovino',
  'E' => 'Equino',
  _ => '',
};

String pluralizeAnimalFamily(String family) {
  final singular = animalFamilyLabel(family);
  if (singular.toLowerCase().endsWith('o')) {
    return '${singular.substring(0, singular.length - 1)}os';
  }
  return singular;
}

String animalFamilyLabel(String family) {
  final trimmed = family.trim();
  switch (trimmed.toUpperCase()) {
    case 'DOG':
    case 'CANINE':
    case 'CANINO':
      return 'Canino';
    case 'CAT':
    case 'FELINE':
    case 'FELINO':
      return 'Felino';
    case 'COW':
    case 'BOVINE':
    case 'BOVINO':
      return 'Bovino';
    case 'HORSE':
    case 'EQUINE':
    case 'EQUINO':
      return 'Equino';
    default:
      if (trimmed.isEmpty) return trimmed;
      return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
  }
}
