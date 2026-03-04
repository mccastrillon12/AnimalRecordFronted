import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'fixed_bottom_action_layout.dart';

class ModalPageLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final Widget? trailingIcon;
  final List<Widget>? headerChildren;
  final Widget? bottomChild;

  const ModalPageLayout({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.trailingIcon,
    this.headerChildren,
    this.bottomChild,
  });

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 80, bottom: 24),
          child: Center(
            child: Text(
              title,
              style: AppTypography.heading2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        Positioned(
          top: 32,
          right: 24,
          child:
              trailingIcon ??
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onClose ?? () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: AppTypography.body4.copyWith(
                        color: const Color(0xFF59667A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onClose ?? () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
        ),
        if (headerChildren != null) ...headerChildren!,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Layout con botón fijo en la parte inferior (igual que MyAccountScreen)
    if (bottomChild != null) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.bgOxford,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.l),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: FixedBottomActionLayout(
                          child: child,
                          bottomChild: bottomChild!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Layout scrollable original (sin botón fijo)
    return Scaffold(
      backgroundColor: AppColors.bgOxford,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.l),
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 100,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_buildHeader(context), child],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
