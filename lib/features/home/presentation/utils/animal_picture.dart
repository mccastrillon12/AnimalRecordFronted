export 'package:animal_record/core/utils/animal_image_url.dart';
import 'package:animal_record/core/constants/app_icons.dart';
import 'animal_family_label.dart';

String animalPictureIcon({
  String species = '',
  String family = '',
  String code = '',
}) {
  for (final candidate in [species, family, animalFamilyFromCode(code)]) {
    switch (candidate.trim().toUpperCase()) {
      case 'CAT':
      case 'FELINE':
      case 'FELINO':
      case 'FELINOS':
      case 'GATO':
        return 'assets/illustrations/cat_icon.svg';
      case 'DOG':
      case 'CANINE':
      case 'CANINO':
      case 'CANINOS':
      case 'PERRO':
        return 'assets/illustrations/dog_icon.svg';
      case 'COW':
      case 'BOVINE':
      case 'BOVINO':
      case 'BOVINOS':
      case 'VACA':
        return 'assets/illustrations/bovino_icon.svg';
      case 'HORSE':
      case 'EQUINE':
      case 'EQUINO':
      case 'EQUINOS':
      case 'CABALLO':
        return 'assets/illustrations/equino_icon.svg';
    }
  }
  return AppIcons.animals;
}
