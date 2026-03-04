import 'dart:io';

void main() async {
  final dir = Directory('lib');

  // Analizar usos de colores
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

  final Map<String, int> colorUsage = {for (var v in declaredColors) v: 0};

  if (await dir.exists()) {
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        String content = await entity.readAsString();
        bool isAppColors = entity.path.endsWith('app_colors.dart');

        for (var color in declaredColors) {
          int count = 0;
          if (isAppColors) {
            count = RegExp(r'=\s*' + color + r'\b').allMatches(content).length;
          } else {
            count = RegExp(
              r'AppColors\.' + color + r'\b',
            ).allMatches(content).length;
          }
          colorUsage[color] = colorUsage[color]! + count;
        }
      }
    }
  }

  List<String> unusedColors = [];
  colorUsage.forEach((color, count) {
    if (count == 0) {
      unusedColors.add(color);
    }
  });

  print('Colores declarados: ${declaredColors.length}');
  print('Colores NO utilizados: ${unusedColors.length}');
  for (var color in unusedColors) {
    print('- $color');
  }

  if (unusedColors.isNotEmpty) {
    List<String> lines = appColorsContent.split('\n');
    List<String> remainingLines = [];
    for (var line in lines) {
      bool keep = true;
      for (var uc in unusedColors) {
        if (line.contains('static const Color $uc =')) {
          keep = false;
          break;
        }
      }
      if (keep) {
        remainingLines.add(line);
      }
    }

    await appColorsFile.writeAsString(remainingLines.join('\n'));
    print('Limpieza completada en app_colors.dart');
  }
}
