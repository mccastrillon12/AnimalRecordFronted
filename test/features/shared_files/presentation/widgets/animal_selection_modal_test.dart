import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/shared_files/presentation/widgets/animal_selection_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('grows Continue only enough to keep it on one line', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(262, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAnimalSelectionModal(
                context: context,
                animals: const [_animal],
                selectedAnimals: const [_animal],
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    final widthGuard = tester.widget<ConstrainedBox>(
      find.byKey(const Key('animal-selection-continue-width')),
    );
    expect(widthGuard.constraints.minWidth, 118);

    final modalRect = tester.getRect(find.byType(AnimalSelectionModal));
    final buttonRect = tester.getRect(find.byType(ElevatedButton));
    expect(buttonRect.center.dx, closeTo(modalRect.center.dx, 0.1));
    expect(buttonRect.width, greaterThan(118));
    expect(buttonRect.width, lessThan(modalRect.width - 88));

    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('Continuar'),
    );
    final boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 9),
    );
    expect(boxes.map((box) => box.top).toSet(), hasLength(1));
    expect(tester.takeException(), isNull);
  });
}

const _animal = AnimalEntity(
  id: 'animal-1',
  name: 'Umi',
  code: 'AR-F025',
  species: 'CAT',
  breed: 'Criollo',
  sex: 'FEMALE',
  reproductiveStatus: 'SPAYED',
  hasChip: false,
  isAssociationMember: false,
  temperament: [],
  diagnosis: [],
  ownerId: 'owner-1',
);
