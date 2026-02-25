import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class ModalPageLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final Widget? trailingIcon;
  final List<Widget>? headerChildren;

  const ModalPageLayout({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.trailingIcon,
    this.headerChildren,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgOxford,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),

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
                        children: [
                          Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 80,
                                  bottom: 24,
                                ),
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
                                    IconButton(
                                      onPressed:
                                          onClose ??
                                          () => Navigator.pop(context),
                                      icon: const Icon(Icons.close),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                              ),
                              if (headerChildren != null) ...headerChildren!,
                            ],
                          ),

                          child,
                        ],
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
