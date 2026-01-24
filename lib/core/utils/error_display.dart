import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';

/// Utility class for displaying error messages to users.
///
/// Provides consistent error display across the application using SnackBars.
class ErrorDisplay {
  /// Shows an error message using a SnackBar.
  ///
  /// [context] is required for showing the SnackBar.
  /// [message] is the error message to display.
  /// [duration] is optional, defaults to 4 seconds.
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: duration,
      ),
    );
  }

  /// Shows a success message using a SnackBar.
  ///
  /// [context] is required for showing the SnackBar.
  /// [message] is the success message to display.
  /// [duration] is optional, defaults to 3 seconds.
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), duration: duration));
  }
}
