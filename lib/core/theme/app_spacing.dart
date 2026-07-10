/// Design system spacing tokens.
///
/// Use these for consistent spacing across the app.
/// Screen-specific constants should live as `static const` in the widget itself.
class AppSpacing {
  // ── Scale tokens (used everywhere) ─────────────────────
  static const double xs = 8.0;
  static const double s = 12.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double xxxl = 56.0;
  static const double xxs = 4.0;

  // ── Input field tokens (shared by CustomTextField, CustomDateField,
  //    AppDropdown, PhoneInputField, IdSelector, dropdowns) ──
  static const double inputHeight = 41.0;
  static const double labelHeight = 18.0;
  static const double inputTopPadding = 4.0;

  // ── Icon sizes ─────────────────────────────────────────
  static const double iconSizeSmall = 24.0;
  static const double iconSizeMedium = 40.0;

  // ── Semantic aliases ───────────────────────────────────
  static const double formPadding = l;
  static const double verticalBetweenElements = l;
  static const double sectionSpacing = xxxl;
}
