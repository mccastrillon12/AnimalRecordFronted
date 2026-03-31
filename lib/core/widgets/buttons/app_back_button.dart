import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_icons.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color color;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: SvgPicture.asset(
        AppIcons.arrowLeft,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        width: 24,
        height: 24,
      ),
      onPressed: onPressed ?? () => Navigator.pop(context),
    );
  }
}
