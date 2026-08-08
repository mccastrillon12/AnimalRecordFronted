import 'package:animal_record/features/home/presentation/utils/animal_family_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('traduce y pluraliza los códigos de especie del backend', () {
    expect(pluralizeAnimalFamily('DOG'), 'Caninos');
    expect(pluralizeAnimalFamily('CAT'), 'Felinos');
    expect(pluralizeAnimalFamily('BOVINE'), 'Bovinos');
    expect(pluralizeAnimalFamily('HORSE'), 'Equinos');
  });

  test('mantiene las familias que ya están en español', () {
    expect(pluralizeAnimalFamily('Canino'), 'Caninos');
    expect(pluralizeAnimalFamily('Felino'), 'Felinos');
  });
}
