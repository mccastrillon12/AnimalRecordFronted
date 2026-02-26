import 'package:flutter/material.dart';

class AppBorders {
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 24.0;
  static const double radiusXXLarge = 32.0;

  static BorderRadius small() => BorderRadius.circular(radiusSmall);
  static BorderRadius medium() => BorderRadius.circular(radiusMedium);
  static BorderRadius large() => BorderRadius.circular(radiusLarge);
  static BorderRadius xLarge() => BorderRadius.circular(radiusXLarge);
  static BorderRadius xxLarge() => BorderRadius.circular(radiusXXLarge);

  static BorderRadius onlyTop(double radius) => BorderRadius.only(
    topLeft: Radius.circular(radius),
    topRight: Radius.circular(radius),
  );

  static BorderRadius onlyBottom(double radius) => BorderRadius.only(
    bottomLeft: Radius.circular(radius),
    bottomRight: Radius.circular(radius),
  );
}
