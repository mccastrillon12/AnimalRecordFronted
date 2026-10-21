import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_shadows.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class MedicalDocumentCard extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onTap;
  final Key? interactionKey;
  final Widget? leading;
  final Widget? title;
  final Widget? trailing;
  final Widget? body;
  final Widget? footer;
  final BorderRadius? borderRadius;
  final CrossAxisAlignment headerCrossAxisAlignment;
  final double trailingSpacing;

  const MedicalDocumentCard({
    super.key,
    this.child,
    this.onTap,
    this.interactionKey,
    this.leading,
    this.title,
    this.trailing,
    this.body,
    this.footer,
    this.borderRadius,
    this.headerCrossAxisAlignment = CrossAxisAlignment.start,
    this.trailingSpacing = AppSpacing.s,
  }) : assert(child != null || title != null);

  @override
  Widget build(BuildContext context) {
    final cardBorderRadius = borderRadius ?? AppBorders.medium();
    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: child ?? _MedicalDocumentCardContent(
        leading: leading,
        title: title!,
        trailing: trailing,
        body: body,
        footer: footer,
        headerCrossAxisAlignment: headerCrossAxisAlignment,
        trailingSpacing: trailingSpacing,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: cardBorderRadius,
        boxShadow: const [AppShadows.card],
      ),
      child: Material(
        color: AppColors.bgBlancoAntiFlash,
        borderRadius: cardBorderRadius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(
                key: interactionKey,
                onTap: onTap,
                borderRadius: cardBorderRadius,
                child: content,
              ),
      ),
    );
  }
}

class _MedicalDocumentCardContent extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? trailing;
  final Widget? body;
  final Widget? footer;
  final CrossAxisAlignment headerCrossAxisAlignment;
  final double trailingSpacing;

  const _MedicalDocumentCardContent({
    required this.title,
    this.leading,
    this.trailing,
    this.body,
    this.footer,
    required this.headerCrossAxisAlignment,
    required this.trailingSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: headerCrossAxisAlignment,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.m),
            ],
            Expanded(child: title),
            if (trailing != null) ...[
              SizedBox(width: trailingSpacing),
              trailing!,
            ],
          ],
        ),
        if (body != null) ...[
          const SizedBox(height: AppSpacing.l),
          body!,
        ],
        if (footer != null) ...[
          const SizedBox(height: AppSpacing.l),
          footer!,
        ],
      ],
    );
  }
}
