import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_card.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_status_tag.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_picture.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final status in ['PENDING', 'TRANSFERRED']) {
    testWidgets('$status usa etiqueta del tamaño de Inactivo solo en lista', (
      tester,
    ) async {
      final animal = AnimalModel(
        id: 'animal-1',
        name: 'Luna',
        code: 'E01',
        family: 'Equino',
        transferStatus: status,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 340,
                child: AnimalCard(
                  animal: animal,
                  mode: AnimalCardMode.compactList,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final label = status == 'PENDING' ? 'Pendiente' : 'Transferido';
      expect(find.text(label), findsOneWidget);
      expect(tester.getSize(find.byType(AnimalCard)).height, 63);
      final tag = tester.widget<Container>(
        find.descendant(
          of: find.byType(AnimalStatusTag),
          matching: find.byType(Container),
        ),
      );
      expect(
        tag.padding,
        const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      );
      final text = tester.widget<Text>(find.text(label));
      expect(text.style?.fontSize, 12);
      expect(
        text.style?.color,
        status == 'PENDING' ? const Color(0xFF2E3949) : const Color(0xFF1E91D6),
      );
      expect(
        (tag.decoration as BoxDecoration).color,
        status == 'PENDING' ? const Color(0xFFE8E9EC) : const Color(0xFFF2F8FF),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 103,
                height: 131,
                child: AnimalCard(animal: animal, mode: AnimalCardMode.grid),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(label), findsNothing);
      expect(find.byType(AnimalStatusTag), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final species in {
    'EQUINE': 'equino',
    'BOVINE': 'bovino',
    'FELINE': 'cat',
    'CANINE': 'dog',
  }.entries) {
    testWidgets('una URL inválida usa el icono de ${species.key}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimalAvatar(
              animal: AnimalModel(
                id: 'animal-1',
                name: 'Luna',
                code: '',
                family: '',
                species: species.key,
                imageUrl: 'not-a-url',
              ),
              size: 32,
              borderRadius: 4,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CachedNetworkImage), findsNothing);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        (svg.bytesLoader as SvgAssetLoader).assetName,
        'assets/illustrations/${species.value}_icon.svg',
      );
    });
  }

  testWidgets(
    'conserva el enlace firmado y notifica su fallo sin mostrarlo en texto',
    (tester) async {
      const url =
          'https://example.com/photo?X-Amz-Signature=a%2Bb%2Fc&expires=300';
      String? failed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimalPicture(
              animal: const AnimalModel(
                id: 'animal-1',
                name: 'Luna',
                code: 'AR-E001',
                family: 'Equino',
                imageUrl: url,
              ),
              width: 32,
              height: 32,
              iconSize: 16,
              onImageError: (value) => failed = value,
            ),
          ),
        ),
      );
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.imageUrl, url);
      image.errorListener!(Exception('Imagen no disponible'));
      await tester.pump();
      expect(failed, url);
      expect(find.textContaining('X-Amz'), findsNothing);
    },
  );
}
