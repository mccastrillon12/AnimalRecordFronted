import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryAzulClaro = Color(0xFF67C1FF);
  static const Color primaryFrances = Color(0xFF0072BB);
  static const Color primaryIndigo = Color(0xFF1A345C);
  static const Color primaryWhite = Color(0xfffcfcfc);

  static const Color secondaryCoral = Color(0xFFF26F49);

  static const Color successEsmeralda = Color(0xFF02CC84);
  static const Color errorRojo = Color(0xFFFA2844);

  static const Color bgRosa = Color(0xFFFFF0F0);
  static const Color bgHielo = Color(0xFFF2F8FF);
  static const Color bgBlancoAntiFlash = Color(0xFFF5F6FA);
  static const Color bgOxford = Color(0xFF091534);
  static const Color semanticAzulMedio = Color(0xFF1E91D6);

  static const LinearGradient backgroundDegrade = LinearGradient(
    begin: Alignment(0.62, -1.0),
    end: Alignment(-2.33, 3.74),
    colors: [
      bgOxford,
      semanticAzulMedio,
    ],
  );

  static const LinearGradient backgroundDegradeFull = LinearGradient(
    begin: Alignment(0.26, -1.0),
    end: Alignment(-0.90, 3.46),
    colors: [
      bgOxford,
      semanticAzulMedio,
    ],
  );

  static const LinearGradient backgroundDegradeAuth = LinearGradient(
    begin: Alignment(0.62, -1.0),
    end: Alignment(-2.33, -0.06),
    colors: [
      bgOxford,
      semanticAzulMedio,
    ],
  );

  static const Color greyBlanco = Color(0xFFFFFFFF);
  static const Color greyDelineante = Color(0xFFE8E9EC);
  static const Color greyBordes = Color(0xFFA8AFBD);
  static const Color greyMedio = Color(0xFF59667A);
  static const Color greyIconos = Color(0xFF59667A);
  static const Color greyIconosBackground = Color(0xFFE8E9EC);
  static const Color greyTextos = Color(0xFF2E3949);
  static const Color greyNegro = Color(0xFF0F1925);
  static const Color greyNegroV2 = Color(0xFF2E3949);
  
  static const Color iosKeyboardGray = Color(0xFFD1D5DF);
  static const Color overlayBlack = Colors.black54;

  static const Color background = bgBlancoAntiFlash;
  static const Color error = errorRojo;
  static const Color textPrimary = greyTextos;
  static const Color textSecondary = greyIconos;
  static const Color border = greyDelineante;

  static const Color white = greyBlanco;
  static const Color greyClaro = greyDelineante;
  static const Color primaryOrange = secondaryCoral;
}
