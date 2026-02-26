import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static final TextStyle heading1 = GoogleFonts.titilliumWeb(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.greyNegro,
    letterSpacing: 0,
  ).copyWith(height: 1.25);

  static final TextStyle heading2 = GoogleFonts.titilliumWeb(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.greyTextos,
  ).copyWith(height: 1.0);

  static final TextStyle body1 = GoogleFonts.notoSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.greyTextos,
  ).copyWith(height: 1.0);

  static final TextStyle body2 = GoogleFonts.notoSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.greyTextos,
  ).copyWith(height: 1.0);

  static final TextStyle body3 = GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.greyTextos,
  ).copyWith(height: 0.875);

  static final TextStyle body4 = GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.greyNegro,
  ).copyWith(height: 1.4);

  static final TextStyle body5 = GoogleFonts.notoSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.greyTextos,
  ).copyWith(height: 0.75);

  static final TextStyle body6 = GoogleFonts.notoSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.greyTextos,
  ).copyWith(height: 0.75);
}
