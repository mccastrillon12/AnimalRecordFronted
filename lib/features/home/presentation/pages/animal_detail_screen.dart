import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/widgets/layout/top_menu_overlay.dart';
import 'package:animal_record/core/widgets/layout/top_menu_trigger.dart';
import 'package:animal_record/core/widgets/display/menu_item_row.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_card.dart';

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

  const AnimalDetailScreen({super.key, required this.animal});

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
    TopMenuItem(
      icon: Icons.calendar_month_outlined,
      label: 'Agenda',
      onTap: () {},
    ),
    TopMenuItem(
      icon: Icons.access_time_rounded,
      label: 'Actividad',
      onTap: () {},
    ),
    TopMenuItem(
      icon: Icons.people_outline_rounded,
      label: 'Profesionales',
      onTap: () {},
    ),
    TopMenuItem(
      icon: Icons.inventory_2_outlined,
      label: 'Archivo',
      onTap: () {},
    ),
    TopMenuItem(
      icon: Icons.home_outlined,
      label: 'Inicio',
      onTap: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    ),
    TopMenuItem(icon: Icons.post_add_rounded, label: '+Historia', onTap: () {}),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
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
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.white,
                            size: 20,
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

                            // Combined Hero Card and Info Section (Exact Figma dimensions)
                            Container(
                              width: 311,
                              height: 339,
                              padding: const EdgeInsets.all(
                                16,
                              ), // 16px padding on all sides per Figma
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: AppBorders.large(),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // The hero image
                                  AnimalCard(
                                    animal: widget.animal,
                                    mode: AnimalCardMode.detailHeader,
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ), // Spacing between image and text
                                  // Info section
                                  Expanded(child: _buildInfoSection()),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.l),

                            // Action buttons
                            _buildActionButtons(),

                            const SizedBox(height: AppSpacing.l),

                            // Options list
                            _buildOptionsList(),

                            const SizedBox(height: AppSpacing.xl),

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
  }

  // ── Info Section ──────────────────────────────────────────────

  Widget _buildInfoSection() {
    final animal = widget.animal;
    final temperamentText = animal.temperament.isNotEmpty
        ? animal.temperament.join(', ')
        : 'No registrado';
    final allergiesText = animal.allergies?.isNotEmpty == true
        ? animal.allergies!
        : 'No registradas';
    final diagnosisText = animal.diagnosis.isNotEmpty
        ? animal.diagnosis.join(', ')
        : 'No registrado';

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Temperamento:', temperamentText),
          const SizedBox(height: 6),
          _buildInfoRow('Alergias a:', allergiesText),
          const SizedBox(height: 6),
          _buildInfoRow('Diagnosticado con:', diagnosisText),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: AppTypography.body6.copyWith(color: AppColors.greyBordes),
          ),
          TextSpan(
            text: value,
            style: AppTypography.body5.copyWith(color: AppColors.greyTextos),
          ),
        ],
      ),
    );
  }

  // ── Action Buttons ────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          icon: Icons.book_outlined,
          label: 'Diario',
          onTap: () {},
        ),
        const SizedBox(width: AppSpacing.xxl),
        _buildActionButton(
          icon: Icons.swap_horiz_rounded,
          label: 'Transferir',
          onTap: () {},
        ),
        const SizedBox(width: AppSpacing.xxl),
        _buildActionButton(
          icon: Icons.share_outlined,
          label: 'Compartir',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: AppBorders.medium(),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 24, color: AppColors.white),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.body6.copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ── Options List ──────────────────────────────────────────────

  Widget _buildOptionsList() {
    final options = [
      'Información',
      'Historia clínica',
      'Carné de vacunas',
      'Desparasitaciones',
      'Órdenes, fórmulas y remisiones',
      'Ayudas diagnosticas',
      'Peso',
      'Genealogía',
    ];

    return Center(
      child: Container(
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
            return MenuItemRow(
              title: entry.value,
              onTap: () {
                // TODO: Navigate to respective sub-screen
              },
              showArrow: true,
            );
          }).toList(),
        ),
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
          width: 32,
          height: 22,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 4),
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
