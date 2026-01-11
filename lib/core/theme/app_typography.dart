import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // --- Titillium Web (Titles) ---
  static TextStyle heading1 = GoogleFonts.titilliumWeb(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.greyNegro,
    letterSpacing: 0,
  );

  static TextStyle heading2 = GoogleFonts.titilliumWeb(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.0,
    color: AppColors.greyTextos,
  );

  // --- Noto Sans (Body) ---
  static TextStyle body1 = GoogleFonts.notoSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.0,
    color: AppColors.greyTextos,
  );

  static TextStyle body2 = GoogleFonts.notoSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: AppColors.greyTextos,
  );

  static TextStyle body3 = GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 0.875,
    color: AppColors.greyTextos,
  );

  static TextStyle body4 = GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.greyNegro,
  );

  static TextStyle body5 = GoogleFonts.notoSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 0.75,
    color: AppColors.greyTextos,
  );

  static TextStyle body6 = GoogleFonts.notoSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 0.75,
    color: AppColors.greyTextos,
  );
}
