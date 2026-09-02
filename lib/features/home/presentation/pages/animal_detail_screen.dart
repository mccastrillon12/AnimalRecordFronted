import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/widgets/layout/top_menu_overlay.dart';
import 'package:animal_record/core/widgets/display/menu_item_row.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_card.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_creation_modal.dart';
import 'package:animal_record/features/home/presentation/pages/animal_empty_feature_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/diary/presentation/pages/animal_diary_screen.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';

typedef MedicalDocumentAvailabilityLoader =
    Future<bool> Function(String animalId, MedicalDocumentCategory category);

/// Detail screen for a single animal.
///
/// Receives an [AnimalModel] and displays:
/// - Hero card with image, name, code, age
/// - Info section (temperament, allergies, diagnosis)
/// - Action buttons (Diario, Transferir, Compartir)
/// - Navigation list (Información, Historia clínica, etc.)
/// - Top menu overlay accessible via trigger
class AnimalDetailScreen extends StatefulWidget {
  final AnimalModel animal;
  final MedicalDocumentAvailabilityLoader? hasMedicalDocuments;

  const AnimalDetailScreen({
    super.key,
    required this.animal,
    this.hasMedicalDocuments,
  });

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  bool _isMenuOpen = false;

  void _toggleMenu() {
    setState(() => _isMenuOpen = !_isMenuOpen);
  }

  void _closeMenu() {
    setState(() => _isMenuOpen = false);
  }

  List<TopMenuItem> get _menuItems => [
    TopMenuItem(svgPath: 'assets/icons/mapa.svg', label: 'Mapa', onTap: () {}),
    TopMenuItem(
      svgPath: 'assets/icons/+animal.svg',
      label: '+ Animal',
      onTap: () {
        _closeMenu();
        showAnimalCreationModal(context);
      },
    ),
    TopMenuItem(
      svgPath: 'assets/icons/agenda.svg',
      label: 'Agenda',
      onTap: () {},
    ),
    TopMenuItem(
      svgPath: 'assets/icons/animales.svg',
      label: 'Mis animales',
      isActive: true,
      onTap: () {},
    ),
    TopMenuItem(
      svgPath: 'assets/icons/inicio.svg',
      label: 'Inicio',
      onTap: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    ),
    TopMenuItem(
      svgPath: 'assets/icons/vacunas.svg',
      label: 'Carné vacunas',
      onTap: () {},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnimalCubit, AnimalState>(
      builder: (context, state) {
        AnimalModel currentAnimal = widget.animal;

        if (state is AnimalsLoaded) {
          try {
            final updatedEntity = state.animals.firstWhere(
              (a) => a.id == widget.animal.id,
            );
            currentAnimal = AnimalModel.fromEntity(updatedEntity);
          } catch (_) {}
        } else if (state is AnimalUpdated) {
          try {
            final updatedEntity = state.allAnimals.firstWhere(
              (a) => a.id == widget.animal.id,
            );
            currentAnimal = AnimalModel.fromEntity(updatedEntity);
          } catch (_) {}
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          child: Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.backgroundDegradeFull,
              ),
              child: Stack(
                children: [
                  // Main content
                  SafeArea(
                    child: Column(
                      children: [
                        // Spacer to prevent the floating menu overlay from obscuring the back button
                        // Height = 8 (margin) + 32 (white container) + 48 (chevron trigger) = 88
                        const SizedBox(height: 55),

                        // Back button row
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.l),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/arrow-left.svg',
                                      width: AppSpacing.iconSizeSmall,
                                      height: AppSpacing.iconSizeSmall,
                                      colorFilter: const ColorFilter.mode(
                                        AppColors.white,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'Atrás',
                                      style: AppTypography.body4.copyWith(
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Scrollable content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing
                                  .l, // 24px padding allows 327px width on 375 screens
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: AppSpacing.xs),

                                // Inactive badge
                                if (!currentAnimal.isActive)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.l,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.bgRosa,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Inactivo',
                                        style: AppTypography.body5.copyWith(
                                          color: AppColors.errorRojo,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Combined Hero Card and Info Section (Dynamic height)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(
                                    AppSpacing.m,
                                  ), // 16px padding on all sides per Figma
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: AppBorders.large(),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // The hero image
                                      AnimalCard(
                                        animal: currentAnimal,
                                        mode: AnimalCardMode.detailHeader,
                                      ),
                                      const SizedBox(
                                        height: 14,
                                      ), // Spacing between image and text
                                      // Info section
                                      _buildInfoSection(currentAnimal),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: AppSpacing.xl),

                                // Action buttons
                                _buildActionButtons(currentAnimal),

                                const SizedBox(height: AppSpacing.xl),

                                // Options list
                                _buildOptionsList(currentAnimal),

                                const SizedBox(height: AppSpacing.l),

                                // Footer logo
                                _buildFooterLogo(),

                                const SizedBox(height: AppSpacing.l),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu overlay (always present at top, handles its own open/close state logic)
                  Positioned.fill(
                    child: TopMenuOverlay(
                      isOpen: _isMenuOpen,
                      onClose: _closeMenu,
                      onToggle: _toggleMenu,
                      items: _menuItems,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Info Section ──────────────────────────────────────────────

  Widget _buildInfoSection(AnimalModel animal) {
    final temperamentText = animal.temperament.isNotEmpty
        ? animal.temperament.join(', ')
        : 'No registrado';
    final allergiesText = animal.allergies?.isNotEmpty == true
        ? animal.allergies!
        : 'No registradas';
    final diagnosisText = animal.diagnosis.isNotEmpty
        ? animal.diagnosis.join(', ')
        : 'No registrado';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Temperamento:', temperamentText),
            const SizedBox(height: 6),
            _buildInfoRow('Alergias a:', allergiesText),
            const SizedBox(height: 6),
            _buildInfoRow('Diagnosticado con:', diagnosisText),
            if (animal.diagnosis.contains('Otro') &&
                animal.otherDiagnosisDetail != null &&
                animal.otherDiagnosisDetail!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildInfoRow('¿Cuál?:', animal.otherDiagnosisDetail!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: AppTypography.body4.copyWith(color: AppColors.greyBordes),
          ),
          TextSpan(text: value, style: AppTypography.body4),
        ],
      ),
    );
  }

  // ── Action Buttons ────────────────────────────────────────────

  Widget _buildActionButtons(AnimalModel currentAnimal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildActionButton(
          iconPath: 'assets/icons/vuesax-bold-book-1.svg',
          label: 'Diario',
          enabled: currentAnimal.isActive,
          onTap: () => _openModalPage(AnimalDiaryScreen(animal: currentAnimal)),
        ),
        const SizedBox(width: 74),
        _buildActionButton(
          iconPath: 'assets/icons/vuesax-bold-send-sqaure-2.svg',
          label: 'Transferir',
          enabled: currentAnimal.isActive,
          onTap: () {},
        ),
        const SizedBox(width: 74),
        _buildActionButton(
          iconPath: 'assets/icons/vuesax-bold-scan-barcode.svg',
          label: 'Compartir',
          enabled: currentAnimal.isActive,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final bgColor = enabled
        ? const Color(0xFF1A345C)
        : Color.alphaBlend(
            Colors.black.withValues(alpha: 0.6),
            const Color(0xFF1A345C),
          );

    final textColor = enabled
        ? AppColors.white.withValues(alpha: 0.85)
        : Color.alphaBlend(
            Colors.black.withValues(alpha: 0.6),
            AppColors.white,
          );

    final iconColor = enabled
        ? AppColors.white
        : Color.alphaBlend(
            Colors.black.withValues(alpha: 0.6),
            AppColors.white,
          );

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 66,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSpacing.iconSizeMedium,
              height: AppSpacing.iconSizeMedium,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: AppBorders.medium(),
              ),
              child: SvgPicture.asset(
                iconPath,
                width: AppSpacing.iconSizeSmall,
                height: AppSpacing.iconSizeSmall,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
            const SizedBox(
              height: AppSpacing.xxs,
            ), // Reduced slightly to fit exactly in 66px with text
            Expanded(
              child: Text(
                label,
                style: AppTypography.body6.copyWith(
                  color: textColor,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Options List ──────────────────────────────────────────────

  Widget _buildOptionsList(AnimalModel animal) {
    final options = [
      'Información',
      'Historia clínica',
      'Carné de vacunas',
      'Peso',
      'Desparasitaciones',
      'Órdenes, fórmulas y remisiones',
      'Imágenes diagnósticas',
      'Resultados de laboratorio',
      'Genealogía',
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppBorders.large(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: options.asMap().entries.map((entry) {
          final isClinicalHistory = entry.value == 'Historia clínica';
          return MenuItemRow(
            key: isClinicalHistory
                ? const Key('animal-clinical-history-menu-item')
                : null,
            title: entry.value,
            onTap: () {
              if (entry.value == 'Información') {
                Navigator.pushNamed(
                  context,
                  AppRoutes.animalInfo,
                  arguments: animal,
                );
              } else if (entry.value == 'Historia clínica') {
                _openClinicalHistory(animal);
              } else if (entry.value == 'Carné de vacunas') {
                Navigator.pushNamed(
                  context,
                  AppRoutes.animalVaccinations,
                  arguments: animal,
                );
              } else if (entry.value == 'Órdenes, fórmulas y remisiones') {
                _openDocumentsSection(animal);
              } else if (entry.value == 'Imágenes diagnósticas') {
                _openMedicalFileSection(
                  animal: animal,
                  category: MedicalDocumentCategory.diagnosticImage,
                  title: 'Imágenes diagnósticas',
                  continueRoute: AppRoutes.animalDiagnosticImages,
                  mainText: 'Actualmente no tiene archivos subidos',
                  subText:
                      'Recopila todas las imágenes\n'
                      'diagnósticas importantes '
                      'del animal.',
                );
              } else if (entry.value == 'Resultados de laboratorio') {
                _openMedicalFileSection(
                  animal: animal,
                  category: MedicalDocumentCategory.laboratoryResult,
                  title: 'Resultados de laboratorio',
                  continueRoute: AppRoutes.animalLaboratoryResults,
                  mainText: 'Actualmente no tiene registros',
                  subText:
                      'Aquí podrá encontrar todos los resultados de '
                      'laboratorio que se suban del animal.',
                );
              }
            },
            showArrow: true,
          );
        }).toList(),
      ),
    );
  }

  void _openClinicalHistory(AnimalModel animal) {
    Navigator.pushNamed(
      context,
      AppRoutes.animalClinicalHistory,
      arguments: animal,
    );
  }

  Future<void> _openDocumentsSection(AnimalModel animal) async {
    late final bool hasDocuments;
    try {
      hasDocuments = await _hasAnyDocuments(
        animal.id,
        const [
          MedicalDocumentCategory.prescription,
          MedicalDocumentCategory.medicalOrder,
          MedicalDocumentCategory.referral,
        ],
      );
    } catch (_) {
      if (mounted) {
        await Navigator.pushNamed(
          context,
          AppRoutes.animalDocuments,
          arguments: animal.id,
        );
      }
      return;
    }
    if (!mounted) return;

    if (hasDocuments) {
      await Navigator.pushNamed(
        context,
        AppRoutes.animalDocuments,
        arguments: animal.id,
      );
      return;
    }
    _openEmptyFeature(
      animal: animal,
      title: 'Fórmulas, órdenes y remisiones',
      continueRoute: AppRoutes.animalDocuments,
      mainText: 'Actualmente no tiene registros',
      subText:
          'Aquí podrá encontrar todas las fórmulas, órdenes y remisiones '
          'médicas que se le han realizado al animal.',
      continueArguments: animal.id,
    );
  }

  Future<void> _openMedicalFileSection({
    required AnimalModel animal,
    required MedicalDocumentCategory category,
    required String title,
    required String continueRoute,
    required String mainText,
    required String subText,
  }) async {
    late final bool hasDocuments;
    try {
      hasDocuments =
          await (widget.hasMedicalDocuments?.call(animal.id, category) ??
              _hasMedicalDocuments(animal.id, category));
    } catch (_) {
      if (mounted) {
        await Navigator.pushNamed(context, continueRoute, arguments: animal);
      }
      return;
    }
    if (!mounted) return;

    if (hasDocuments) {
      await Navigator.pushNamed(context, continueRoute, arguments: animal);
      return;
    }
    _openEmptyFeature(
      animal: animal,
      title: title,
      continueRoute: continueRoute,
      mainText: mainText,
      subText: subText,
    );
  }

  Future<bool> _hasMedicalDocuments(
    String animalId,
    MedicalDocumentCategory category,
  ) async {
    final documents = await di.sl<GetAnimalMedicalDocumentsUseCase>()(
      animalId,
      category: category,
    );
    return documents.isNotEmpty;
  }

  Future<bool> _hasAnyDocuments(
    String animalId,
    List<MedicalDocumentCategory> categories,
  ) async {
    final availability = await Future.wait(
      categories.map(
        (category) =>
            widget.hasMedicalDocuments?.call(animalId, category) ??
            _hasMedicalDocuments(animalId, category),
      ),
    );
    return availability.any((hasDocuments) => hasDocuments);
  }

  void _openEmptyFeature({
    required AnimalModel animal,
    required String title,
    required String continueRoute,
    required String mainText,
    required String subText,
    Object? continueArguments,
  }) {
    _openModalPage(
      AnimalEmptyFeatureScreen(
        animalFamily: animal.family,
        title: title,
        mainText: mainText,
        subText: subText,
        onContinue: () => Navigator.pushReplacementNamed(
          context,
          continueRoute,
          arguments: continueArguments ?? animal,
        ),
      ),
    );
  }

  void _openModalPage(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.ease));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  // ── Footer Logo ───────────────────────────────────────────────

  Widget _buildFooterLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/Logo/Imagotipo_blanco.png',
          width: AppSpacing.xl,
          height: 22,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'ANIMAL RECORD',
          style: AppTypography.body6.copyWith(
            color: AppColors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
