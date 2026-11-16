import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/layout/fixed_bottom_action_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimalTransferSuccessScreen extends StatelessWidget {
  static const _backgroundGradient = LinearGradient(
    begin: Alignment(1.5, -0.5),
    end: Alignment(-1.5, 0.5),
    colors: [AppColors.bgOxford, Color(0xFF124C7C)],
  );
  final String recipientName;
  final VoidCallback onFinish;

  const AnimalTransferSuccessScreen({
    super.key,
    required this.recipientName,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final illustrationSize = (MediaQuery.sizeOf(context).width * 283 / 375)
        .clamp(0.0, 340.0);
    final bodyStyle = AppTypography.body6.copyWith(
      color: AppColors.white,
      height: 1.5,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bgOxford,
        body: Container(
          decoration: const BoxDecoration(gradient: _backgroundGradient),
          child: SafeArea(
            child: FixedBottomActionLayout(
              bottomChild: CustomButton(
                key: const Key('transfer-finish'),
                text: 'Finalizar',
                onPressed: onFinish,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l,
                  0,
                  AppSpacing.l,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SizedBox(
                        key: const Key('transfer-success-illustration'),
                        width: illustrationSize,
                        height: illustrationSize,
                        child: SvgPicture.asset(
                          'assets/illustrations/add-friend-on-social-media.svg',
                          width: illustrationSize,
                          height: illustrationSize,
                          semanticsLabel: 'Transferencia de animales',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      'Transferencia exitosa',
                      style: AppTypography.heading1.copyWith(
                        color: AppColors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 330),
                        child: Text.rich(
                          TextSpan(
                            text:
                                'El o los animales han sido transferidos al usuario ',
                            style: AppTypography.body2.copyWith(
                              color: AppColors.white,
                              height: 1.6,
                            ),
                            children: [
                              TextSpan(
                                text: recipientName,
                                style: AppTypography.body1.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'El usuario debe ingresar a su aplicación y aceptar los animales.',
                                style: bodyStyle,
                              ),
                              const SizedBox(height: AppSpacing.m),
                              Text(
                                'Si esto no sucede en X días o los rechaza, volverás a visualizarlos en tu cuenta.',
                                style: bodyStyle,
                              ),
                              const SizedBox(height: AppSpacing.m),
                              Text.rich(
                                TextSpan(
                                  text: 'Por lo pronto, estarán en estado ',
                                  style: bodyStyle,
                                  children: [
                                    TextSpan(
                                      text: 'pendiente',
                                      style: AppTypography.body5.copyWith(
                                        color: AppColors.white,
                                      ),
                                    ),
                                    const TextSpan(
                                      text:
                                          ' y no podrás acceder a sus historias',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
