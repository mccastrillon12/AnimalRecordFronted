enum AnimalFamily {
  felino,
  canino,
  bovino,
  equino;

  String get displayName {
    switch (this) {
      case AnimalFamily.felino:
        return 'Felino';
      case AnimalFamily.canino:
        return 'Canino';
      case AnimalFamily.bovino:
        return 'Bovino';
      case AnimalFamily.equino:
        return 'Equino';
    }
  }

  String get iconAsset {
    switch (this) {
      case AnimalFamily.felino:
        return 'assets/illustrations/cat_icon.svg';
      case AnimalFamily.canino:
        return 'assets/illustrations/dog_icon.svg';
      case AnimalFamily.bovino:
        return 'assets/illustrations/bovino_icon.svg';
      case AnimalFamily.equino:
        return 'assets/illustrations/equino_icon.svg';
    }
  }

  /// Maps to the API `species` field value.
  String get apiSpecies {
    switch (this) {
      case AnimalFamily.felino:
        return 'CAT';
      case AnimalFamily.canino:
        return 'DOG';
      case AnimalFamily.bovino:
        return 'BOVINE';
      case AnimalFamily.equino:
        return 'HORSE';
    }
  }
}
