import 'package:animal_record/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppLoadingOverlay {
  final Color barrierColor;
  OverlayEntry? _entry;

  AppLoadingOverlay({this.barrierColor = Colors.transparent});

  bool get isVisible => _entry != null;

  void show(BuildContext context) {
    if (isVisible) return;

    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: Stack(
          children: [
            Positioned.fill(
              child: ModalBarrier(color: barrierColor, dismissible: false),
            ),
            const Center(
              child: SizedBox.square(
                dimension: 36,
                child: CircularProgressIndicator(
                  color: AppColors.primaryFrances,
                  semanticsLabel: 'Cargando',
                ),
              ),
            ),
          ],
        ),
      ),
    );
    _entry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void hide() {
    final entry = _entry;
    if (entry == null) return;

    _entry = null;
    entry.remove();
    entry.dispose();
  }
}
