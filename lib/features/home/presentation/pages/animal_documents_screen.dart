import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/utils/error_display.dart';

class AnimalDocumentsScreen extends StatefulWidget {
  final String animalId;

  const AnimalDocumentsScreen({super.key, required this.animalId});

  @override
  State<AnimalDocumentsScreen> createState() => _AnimalDocumentsScreenState();
}

class _AnimalDocumentsScreenState extends State<AnimalDocumentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String? _searchErrorText;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      FocusManager.instance.primaryFocus?.unfocus();
      if (mounted) {
        setState(() {
          _searchController.clear();
          _searchErrorText = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundDegrade,
          ),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: const SizedBox(height: AppSpacing.l),
              ),
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
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          // Close button & Title
                          Stack(
                            children: [
                              // Title
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 80, // Matches Figma
                                  bottom: AppSpacing.l, // 24px
                                  left: AppSpacing.l, // 24px
                                  right: AppSpacing.l, // 24px
                                ),
                                child: Center(
                                  child: Text(
                                    'Fórmulas, órdenes y remisiones',
                                    style: AppTypography.heading2.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              // Close button
                              Positioned(
                                top: AppSpacing.l, // 24px
                                right: AppSpacing.l, // 24px
                                child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(
                                    Icons.close,
                                    color: AppColors.greyIconos,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),

                          // Tab bar with bottom shadow (clipped at the top)
                          ClipRect(
                            clipper: _BottomShadowClipper(),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0F1925,
                                    ).withValues(alpha: 0.08),
                                    offset: const Offset(0, 4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: TabBar(
                                controller: _tabController,
                                labelPadding: EdgeInsets.zero,
                                dividerColor: Colors.transparent,
                                labelColor: AppColors.textPrimary,
                                unselectedLabelColor: AppColors.greyMedio,
                                labelStyle: AppTypography.body3.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                unselectedLabelStyle: AppTypography.body4,
                                indicatorColor: AppColors.primaryFrances,
                                indicatorWeight: 2,
                                indicatorSize: TabBarIndicatorSize.label,
                                tabs: const [
                                  Tab(text: 'Fórmulas'),
                                  Tab(text: 'Órdenes'),
                                  Tab(text: 'Remisiones'),
                                ],
                              ),
                            ),
                          ),

                          // Search bar
                          const SizedBox(height: AppSpacing.l),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.l,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: AppSpacing.iconSizeMedium,
                                  child: TextField(
                                    controller: _searchController,
                                    style: AppTypography.body4,
                                    textAlignVertical: TextAlignVertical.center,
                                    inputFormatters: [
                                      ErrorTriggeringTextInputFormatter(
                                        allowPattern: RegExp(
                                          r'^[a-zA-Z0-9\s]+$',
                                        ),
                                        maxLength: 20,
                                        onError: (error) {
                                          if (_searchErrorText != error) {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  if (mounted) {
                                                    setState(
                                                      () => _searchErrorText =
                                                          error,
                                                    );
                                                  }
                                                });
                                          }
                                        },
                                        onSuccess: () {
                                          if (_searchErrorText != null) {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  if (mounted) {
                                                    setState(
                                                      () => _searchErrorText =
                                                          null,
                                                    );
                                                  }
                                                });
                                          }
                                        },
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: AppColors.white,
                                      isDense: true,
                                      hintText: 'Buscar',
                                      hintStyle: AppTypography.body4.copyWith(
                                        color: AppColors.greyBordes,
                                      ),
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 16,
                                          right: 8,
                                        ),
                                        child: SvgPicture.asset(
                                          'assets/icons/vuesax-linear-search-2.svg',
                                          width: AppSpacing.iconSizeSmall,
                                          height: AppSpacing.iconSizeSmall,
                                          colorFilter: const ColorFilter.mode(
                                            Color(0xFF59667A),
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                                      prefixIconConstraints:
                                          const BoxConstraints(
                                            minWidth: 0,
                                            minHeight: 0,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: _searchErrorText != null
                                              ? AppColors.error
                                              : const Color(0xFFA8AFBD),
                                          width: 1,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: _searchErrorText != null
                                              ? AppColors.error
                                              : const Color(0xFFA8AFBD),
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: _searchErrorText != null
                                              ? AppColors.error
                                              : const Color(0xFF0072BB),
                                          width: 1,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 11,
                                          ),
                                    ),
                                  ),
                                ),
                                if (_searchErrorText != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _searchErrorText!,
                                    style: AppTypography.body5.copyWith(
                                      color: AppColors.error,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),

                          // Tab content (empty states for now)
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildEmptyState(
                                  'El registro de fórmulas está vacío',
                                  'Aquí se podrán visualizar las fórmulas\nmédicas que se creen.',
                                ),
                                _buildEmptyState(
                                  'El registro de órdenes está vacío',
                                  'Aquí se podrán visualizar las órdenes\nmédicas que se creen.',
                                ),
                                _buildEmptyState(
                                  'El registro de remisiones está vacío',
                                  'Aquí se podrán visualizar las remisiones\nmédicas que se creen.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // FAB
                      Positioned(
                        right: AppSpacing.l,
                        bottom: AppSpacing.l,
                        child: _buildFab(context),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: MediaQuery.of(context).padding.bottom,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String description) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: AppTypography.body3.copyWith(
            color: AppColors.greyTextos,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          description,
          style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 100,
        ), // Spacing to balance the visual center taking FAB into account
      ],
    );
  }

  Widget _buildFab(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'subir_documento') {
            final animals = context.read<AnimalCubit>().animals;
            final matches = animals.where(
              (animal) => animal.id == widget.animalId,
            );
            if (matches.isEmpty) {
              ErrorDisplay.showError(
                context,
                'No fue posible cargar la información del animal.',
              );
              return;
            }

            Navigator.pushNamed(
              context,
              AppRoutes.sharedFileUpload,
              arguments: {
                'manualUpload': true,
                'preselectedAnimal': matches.first,
              },
            );
          }
        },
        offset: const Offset(
          0,
          -68,
        ), // Matches the exact 5px gap from MyAnimalsContent
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
        ),
        constraints: const BoxConstraints(minWidth: 203, maxWidth: 203),
        color: AppColors.white,
        elevation: 4,
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'subir_documento',
            height: 47,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/document-upload.svg',
                  width: AppSpacing.iconSizeSmall,
                  height: AppSpacing.iconSizeSmall,
                ),
                const SizedBox(width: 10),
                Text(
                  'Subir documentos',
                  style: AppTypography.body4.copyWith(
                    color: AppColors.greyTextos,
                  ),
                ),
              ],
            ),
          ),
        ],
        child: Container(
          width: AppSpacing.iconSizeMedium,
          height: AppSpacing.iconSizeMedium,
          decoration: BoxDecoration(
            color: AppColors.secondaryCoral,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryCoral.withValues(alpha: 0.4),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.more_vert_rounded,
            color: AppColors.white,
            size: AppSpacing.iconSizeSmall,
          ),
        ),
      ),
    );
  }
}

class _BottomShadowClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    // Allows the shadow to cast on the left, right, and bottom, but clips the top (y < 0).
    return Rect.fromLTRB(-100, 0, size.width + 100, size.height + 100);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}
