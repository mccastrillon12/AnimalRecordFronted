import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'la presentación de transferencias y el dominio no dependen de implementaciones data',
    () {
      for (final feature in ['home', 'diary', 'medical_documents']) {
        for (final layer in ['presentation', 'domain']) {
          final files = Directory('lib/features/$feature/$layer')
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'));
          for (final file in files) {
            final imports = file.readAsLinesSync().where(
              (line) => line.startsWith('import '),
            );
            expect(
              imports.where(
                (line) => RegExp(r'features/[^/]+/data/').hasMatch(line),
              ),
              isEmpty,
              reason: file.path,
            );
          }
        }
      }
    },
  );
}
