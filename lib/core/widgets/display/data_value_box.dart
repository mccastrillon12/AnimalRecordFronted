import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class DataValueBox extends StatelessWidget {
  final String value;
  final EdgeInsetsGeometry padding;

  const DataValueBox({
    super.key,
    required this.value,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyClaro),
      ),
      child: Text(
        value,
        style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
