import 'package:animal_record/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_borders.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary
            ? AppColors.primaryWhite
            : AppColors.secondaryCoral,
        foregroundColor: isSecondary
            ? AppColors.greyTextos
            : AppColors.primaryWhite,
        elevation: 0,
        minimumSize: const Size(double.infinity, 36),
        textStyle: AppTypography.body3,
        shape: RoundedRectangleBorder(borderRadius: AppBorders.medium()),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(text),
    );
  }
}
