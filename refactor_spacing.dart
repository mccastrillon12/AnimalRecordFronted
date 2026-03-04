import 'dart:io';

void main() async {
  final directories = [
    Directory('lib/features'),
    Directory('lib/core/widgets'),
    Directory('lib/core/theme'),
  ];

  // 1. Reemplazo de espaciados / magic numbers
  final spacingReplacements = {
    'SizedBox(height: 8)': 'const SizedBox(height: AppSpacing.xs)',
    'SizedBox(height: 12)': 'const SizedBox(height: AppSpacing.s)',
    'SizedBox(height: 16)': 'const SizedBox(height: AppSpacing.m)',
    'SizedBox(height: 24)': 'const SizedBox(height: AppSpacing.l)',
    'SizedBox(height: 32)': 'const SizedBox(height: AppSpacing.xl)',
    'SizedBox(height: 40)': 'const SizedBox(height: AppSpacing.xxl)',
    'SizedBox(width: 8)': 'const SizedBox(width: AppSpacing.xs)',
    'SizedBox(width: 12)': 'const SizedBox(width: AppSpacing.s)',
    'SizedBox(width: 16)': 'const SizedBox(width: AppSpacing.m)',
    'SizedBox(width: 24)': 'const SizedBox(width: AppSpacing.l)',
    'SizedBox(width: 32)': 'const SizedBox(width: AppSpacing.xl)',
  };

  int spacingModified = 0;

  for (final dir in [directories[0], directories[1]]) {
    if (!await dir.exists()) continue;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        String content = await entity.readAsString();
        String originalContent = content;

        // Reemplazos de espaciado
        spacingReplacements.forEach((key, value) {
          content = content.replaceAll(key, value);
          // Omitir const duplicados
          content = content.replaceAll('const $value', value);
        });

        // Agregar import si se usó AppSpacing y no existía
        if (content != originalContent && content.contains('AppSpacing')) {
          if (!content.contains('app_spacing.dart')) {
            // heuristica simple para agregar el import al inicio
            content =
                "import 'package:animal_record/core/theme/app_spacing.dart';\n" +
                content;
          }
          await entity.writeAsString(content);
          spacingModified++;
          print('Spacing Refactored: ${entity.path}');
        }
      }
    }
  }

  print('Done Spacing. Files modified: $spacingModified');

  // 2. Analizar usos de colores
  final appColorsFile = File('lib/core/theme/app_colors.dart');
  final appColorsContent = await appColorsFile.readAsString();

  final colorRegex = RegExp(r'static const Color (\w+) =');
  final matches = colorRegex.allMatches(appColorsContent);
  final List<String> declaredColors = [];

  for (var match in matches) {
    if (match.groupCount >= 1) {
      declaredColors.add(match.group(1)!);
    }
  }

  print('Declared colors: \${declaredColors.length}');

  final Map<String, int> colorUsage = {for (var v in declaredColors) v: 0};

  for (final dir in directories) {
    if (!await dir.exists()) continue;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File &&
          entity.path.endsWith('.dart') &&
          !entity.path.endsWith('app_colors.dart')) {
        String content = await entity.readAsString();
        for (var color in declaredColors) {
          // check 'AppColors.colorName'
          if (content.contains('AppColors.\$color') ||
              content.contains('.\$color,')) {
            // a bit hacky but catches within the theme itself sometimes
            colorUsage[color] = colorUsage[color]! + 1;
          }
        }
      }
    }
  }

  print('--- Colors Usage ---');
  colorUsage.forEach((color, count) {
    if (count == 0) {
      print('UNUSED: \$color');
    }
  });
}
