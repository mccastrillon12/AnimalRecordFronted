import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Wraps complete words and only truncates words wider than the label column.
class AnalysisDetailLabel extends StatelessWidget {
  final String label;
  final double width;

  const AnalysisDetailLabel({super.key, required this.label, this.width = 119});

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.body4.copyWith(color: AppColors.greyBordes);
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final painter = TextPainter(
      textDirection: direction,
      textScaler: textScaler,
      locale: Localizations.maybeLocaleOf(context),
    );
    bool fits(String text) {
      painter.text = TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      );
      painter.layout();
      return painter.width <= width;
    }

    String ellipsize(String text) {
      if (fits(text)) return text;
      final characters = text.characters.toList();
      while (characters.isNotEmpty &&
          !fits('${characters.join().trimRight()}...')) {
        characters.removeLast();
      }
      return '${characters.join().trimRight()}...';
    }

    final lines = <List<String>>[];
    for (final word in label.trim().split(RegExp(r'\s+'))) {
      if (lines.isEmpty || !fits([...lines.last, word].join(' '))) {
        lines.add([word]);
      } else {
        lines.last.add(word);
      }
    }
    if (lines.length > 1 && lines.last.length == 1) {
      final previous = lines[lines.length - 2];
      if (previous.length > 1 &&
          fits([previous.last, ...lines.last].join(' '))) {
        lines.last.insert(0, previous.removeLast());
      }
    }
    final display = lines.map((line) => ellipsize(line.join(' '))).join('\n');
    painter.dispose();
    return Text(display, semanticsLabel: label, style: style, softWrap: false);
  }
}
