import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';

class CustomDateField extends StatelessWidget {
  final String label;
  final String hint;
  final DateTime? value;
  final ValueChanged<DateTime>? onChanged;
  final bool enabled;
  final bool showAge;

  const CustomDateField({
    super.key,
    required this.label,
    this.hint = 'month dd, yyyy',
    this.value,
    this.onChanged,
    this.enabled = true,
    this.showAge = false,
  });

  String _formatDate(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    final monthName = months[date.month - 1];
    final dayStr = date.day.toString().padLeft(2, '0');
    final formattedDate = '$monthName $dayStr, ${date.year}';

    if (!showAge) return formattedDate;

    final now = DateTime.now();
    int ageYears = now.year - date.year;
    int ageMonths = now.month - date.month;

    if (now.day < date.day) {
      ageMonths--;
    }

    if (ageMonths < 0) {
      ageYears--;
      ageMonths += 12;
    }

    String ageDisplay = '';
    if (ageYears > 0) {
      ageDisplay = '$ageYears ${ageYears == 1 ? 'año' : 'años'}';
    } else if (ageMonths > 0) {
      ageDisplay = '$ageMonths ${ageMonths == 1 ? 'mes' : 'meses'}';
    } else {
      final days = now.difference(date).inDays;
      if (days > 0) {
        ageDisplay = '$days ${days == 1 ? 'día' : 'días'}';
      } else {
        ageDisplay = 'Recién nacido';
      }
    }

    return '$formattedDate ($ageDisplay)';
  }

  Future<void> _pickDate(BuildContext context) async {
    if (!enabled) return;

    final now = DateTime.now();
    DateTime tempDate = value ?? now;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return Localizations.override(
          context: context,
          locale: const Locale('es', 'ES'),
          delegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          child: Theme(
          data: Theme.of(context).copyWith(
            textTheme: GoogleFonts.notoSansTextTheme(Theme.of(context).textTheme),
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryFrances,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.greyTextos,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryFrances,
                textStyle: AppTypography.body3,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          child: Transform.scale(
            scale: 0.85,
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Compact header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Seleccionar fecha', style: AppTypography.body6.copyWith(color: AppColors.greyMedio)),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(tempDate),
                                  style: AppTypography.heading1.copyWith(fontSize: 24),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          
                          // Calendar body
                          CalendarDatePicker(
                            initialDate: tempDate,
                            firstDate: DateTime(1990),
                            lastDate: now,
                            onDateChanged: (DateTime date) {
                              setState(() {
                                tempDate = date;
                              });
                            },
                          ),

                          // Actions tightly packed
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                const SizedBox(width: 16),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, tempDate),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ));
      },
    );

    if (picked != null) {
      onChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          SizedBox(
            height: 18,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(label, style: AppTypography.body6),
            ),
          ),

        if (label.isNotEmpty)
          const SizedBox(height: AppSpacing.inputTopPadding),

        GestureDetector(
          onTap: () => _pickDate(context),
          child: Container(
            height: AppSpacing.inputHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: enabled ? AppColors.white : const Color(0xFFF5F6FA),
              borderRadius: AppBorders.small(),
              border: Border.all(color: AppColors.greyBordes, width: 1.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null ? _formatDate(value!) : hint,
                    style: AppTypography.body4.copyWith(
                      color: value != null
                          ? AppColors.greyNegroV2
                          : AppColors.greyBordes,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppColors.greyMedio,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
