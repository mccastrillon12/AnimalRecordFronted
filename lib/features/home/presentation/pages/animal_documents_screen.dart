import 'dart:async';

import 'package:animal_record/core/injection_container.dart' as di;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_document_upload_menu.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/data/datasources/medical_document_ai_feedback_local_datasource.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/animal_medical_documents_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  int _loadedTabIndex = 0;
  final Set<MedicalDocumentCategory> _pendingAiFeedbackCategories = {};
  final Set<MedicalDocumentCategory> _answeredAiFeedbackCategories = {};
  final Map<MedicalDocumentCategory, Future<void>> _pendingFeedbackWrites = {};
  late final MedicalDocumentAiFeedbackLocalDataSource _aiFeedbackStore;
  int _aiFeedbackRequestId = 0;

  static const _feedbackCategories = {
    MedicalDocumentCategory.prescription,
    MedicalDocumentCategory.medicalOrder,
    MedicalDocumentCategory.referral,
  };

  @override
  void initState() {
    super.initState();
    _aiFeedbackStore = di.sl<MedicalDocumentAiFeedbackLocalDataSource>();
    _pendingAiFeedbackCategories.addAll(
      _feedbackCategories.where(
        (category) => _aiFeedbackStore.isPending(widget.animalId, category),
      ),
    );
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      FocusManager.instance.primaryFocus?.unfocus();
      if (_loadedTabIndex != _tabController.index) {
        _loadedTabIndex = _tabController.index;
        context.read<AnimalMedicalDocumentsCubit>().load(
          widget.animalId,
          category: _categoryForIndex(_loadedTabIndex),
        );
      }
      if (mounted) {
        setState(() {
          _searchController.clear();
          _searchErrorText = null;
        });
      }
    });
    _searchController.addListener(_refreshSearch);
  }

  void _refreshSearch() => setState(() {});

  MedicalDocumentCategory _categoryForIndex(int index) => switch (index) {
    0 => MedicalDocumentCategory.prescription,
    1 => MedicalDocumentCategory.medicalOrder,
    _ => MedicalDocumentCategory.referral,
  };

  void _handleUploadedDocument() {
    final category = _categoryForIndex(_tabController.index);
    setState(() {
      _pendingAiFeedbackCategories.add(category);
      _answeredAiFeedbackCategories.remove(category);
      _aiFeedbackRequestId++;
    });
    final write = _aiFeedbackStore.markPending(widget.animalId, category);
    _pendingFeedbackWrites[category] = write;
    unawaited(write.catchError((_) {}));
    context.read<AnimalMedicalDocumentsCubit>().refreshAfterUpload(
      widget.animalId,
      category: category,
    );
  }

  void _dismissAiFeedback(MedicalDocumentCategory category) {
    if (!_pendingAiFeedbackCategories.contains(category)) return;
    setState(() {
      _pendingAiFeedbackCategories.remove(category);
      _answeredAiFeedbackCategories.remove(category);
    });
  }

  Future<void> _markAiFeedbackAnswered(MedicalDocumentCategory category) async {
    try {
      await _pendingFeedbackWrites.remove(category);
    } catch (_) {
      // A failed pending write must not cause the already-submitted vote
      // to be sent twice.
    }
    try {
      await _aiFeedbackStore.clearPending(widget.animalId, category);
    } catch (_) {
      // The backend already accepted the anonymous vote. Keep the UI answered.
    }
    if (!mounted) return;
    setState(() => _answeredAiFeedbackCategories.add(category));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_refreshSearch);
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

                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                AnimalMedicalDocumentsView(
                                  animalId: widget.animalId,
                                  category:
                                      MedicalDocumentCategory.prescription,
                                  showAiFeedback: _pendingAiFeedbackCategories
                                      .contains(
                                        MedicalDocumentCategory.prescription,
                                      ),
                                  aiFeedbackRequestId: _aiFeedbackRequestId,
                                  initialAiFeedbackResponded:
                                      _answeredAiFeedbackCategories.contains(
                                        MedicalDocumentCategory.prescription,
                                      ),
                                  onAiFeedbackSubmitted: () =>
                                      _markAiFeedbackAnswered(
                                        MedicalDocumentCategory.prescription,
                                      ),
                                  onAiFeedbackDismissed: () =>
                                      _dismissAiFeedback(
                                        MedicalDocumentCategory.prescription,
                                      ),
                                  searchQuery: _searchController.text,
                                  emptyTitle:
                                      'El registro de fórmulas está vacío',
                                  emptyDescription:
                                      'Aquí se podrán visualizar las fórmulas médicas que se creen.',
                                ),
                                AnimalMedicalDocumentsView(
                                  animalId: widget.animalId,
                                  category:
                                      MedicalDocumentCategory.medicalOrder,
                                  showAiFeedback: _pendingAiFeedbackCategories
                                      .contains(
                                        MedicalDocumentCategory.medicalOrder,
                                      ),
                                  aiFeedbackRequestId: _aiFeedbackRequestId,
                                  initialAiFeedbackResponded:
                                      _answeredAiFeedbackCategories.contains(
                                        MedicalDocumentCategory.medicalOrder,
                                      ),
                                  onAiFeedbackSubmitted: () =>
                                      _markAiFeedbackAnswered(
                                        MedicalDocumentCategory.medicalOrder,
                                      ),
                                  onAiFeedbackDismissed: () =>
                                      _dismissAiFeedback(
                                        MedicalDocumentCategory.medicalOrder,
                                      ),
                                  searchQuery: _searchController.text,
                                  emptyTitle:
                                      'El registro de órdenes está vacío',
                                  emptyDescription:
                                      'Aquí se podrán visualizar las órdenes médicas que se creen.',
                                ),
                                AnimalMedicalDocumentsView(
                                  animalId: widget.animalId,
                                  category: MedicalDocumentCategory.referral,
                                  showAiFeedback: _pendingAiFeedbackCategories
                                      .contains(
                                        MedicalDocumentCategory.referral,
                                      ),
                                  aiFeedbackRequestId: _aiFeedbackRequestId,
                                  initialAiFeedbackResponded:
                                      _answeredAiFeedbackCategories.contains(
                                        MedicalDocumentCategory.referral,
                                      ),
                                  onAiFeedbackSubmitted: () =>
                                      _markAiFeedbackAnswered(
                                        MedicalDocumentCategory.referral,
                                      ),
                                  onAiFeedbackDismissed: () =>
                                      _dismissAiFeedback(
                                        MedicalDocumentCategory.referral,
                                      ),
                                  searchQuery: _searchController.text,
                                  emptyTitle:
                                      'El registro de remisiones está vacío',
                                  emptyDescription:
                                      'Aquí se podrán visualizar las remisiones médicas que se creen.',
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
                        child: AnimalDocumentUploadMenu(
                          animalId: widget.animalId,
                          requestedCategory: _categoryForIndex(
                            _tabController.index,
                          ),
                          onUploaded: _handleUploadedDocument,
                        ),
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
