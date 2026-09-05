import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/dropdowns/app_multi_search_dropdown.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/feedback/process_cancellation_dialog.dart';
import 'package:animal_record/core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/home/presentation/navigation/home_section_navigation.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/data/datasources/medical_document_ai_feedback_local_datasource.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/medical_document_flow_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/medical_document_flow_state.dart';
import 'package:animal_record/features/medical_documents/presentation/pages/medical_document_review_screen.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_classification_dialog.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_cubit.dart';
import 'package:animal_record/features/shared_files/presentation/shared_file_upload_feedback.dart';
import 'package:animal_record/features/shared_files/presentation/shared_file_upload_result.dart';
import 'package:animal_record/features/shared_files/presentation/widgets/animal_selection_modal.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:animal_record/features/shared_files/domain/entities/manual_file_source.dart';
import 'package:animal_record/features/shared_files/domain/usecases/pick_manual_shared_file_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io' as io;

class SharedFileUploadScreen extends StatefulWidget {
  const SharedFileUploadScreen({super.key});

  @override
  State<SharedFileUploadScreen> createState() => _SharedFileUploadScreenState();
}

class _SharedFileUploadScreenState extends State<SharedFileUploadScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _fileNameController;
  final TextEditingController _descriptionController = TextEditingController();
  List<AnimalEntity> _selectedAnimals = const [];
  SharedFileEntity? _manualFile;
  DateTime? _manualFileSelectedAt;
  bool _reviewPresented = false;
  bool _pendingResumeChecked = false;
  bool _classificationCancellationConfirmed = false;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final files = context.read<SharedFilesCubit>().pendingFiles;
    _fileNameController = TextEditingController(
      text: files.isEmpty ? '' : files.first.name,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthSuccess) {
        await context.read<AnimalCubit>().loadAnimals(authState.user.id);
      }
      if (mounted && _shouldResumePending) {
        await _resumeCompatiblePendingFlow();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedAnimals.isEmpty) {
      final preselected = _preselectedAnimal;
      if (preselected != null) {
        _selectedAnimals = [preselected];
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fileNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final flow = context.read<MedicalDocumentFlowCubit>();
    if (state == AppLifecycleState.resumed &&
        flow.state.phase == MedicalDocumentFlowPhase.pollingPaused) {
      flow.resumePolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      flow.pausePolling();
    }
  }

  Future<bool> _discardPendingFlow() async {
    final flow = context.read<MedicalDocumentFlowCubit>();
    final discarded = await flow.discardCurrentFlow();
    if (!discarded && mounted) {
      ErrorDisplay.showError(
        context,
        flow.state.message ??
            'No fue posible cancelar el análisis. Inténtalo nuevamente.',
      );
    }
    return discarded;
  }

  Future<void> _close() async {
    if (_isClosing) return;
    _isClosing = true;
    if (_hasEnteredData) {
      final confirmed = await showProcessCancellationDialog(context);
      if (!mounted) return;
      if (!confirmed) {
        _isClosing = false;
        return;
      }
    }
    await _cancelAndClose();
  }

  bool get _hasEnteredData {
    final sharedFiles = context.read<SharedFilesCubit>();
    final flow = context.read<MedicalDocumentFlowCubit>();
    final hasSourceFile = _isManualUpload
        ? _manualFile != null
        : sharedFiles.pendingFiles.isNotEmpty;
    return hasSourceFile ||
        _selectedAnimals.isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        flow.state.phase != MedicalDocumentFlowPhase.selecting ||
        flow.pendingFlow != null;
  }

  Future<void> _cancelAndClose() async {
    if (!await _discardPendingFlow() || !mounted) return;
    if (!_isManualUpload) {
      context.read<SharedFilesCubit>().clear();
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(false);
    } else {
      navigator.pushNamedAndRemoveUntil(
        AppRoutes.home,
        (_) => false,
        arguments: const {homeInitialSectionArgument: homeMyAnimalsSection},
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final overlay = navigator.overlay;
        if (overlay != null) {
          ErrorDisplay.showError(overlay.context, sharedFileUploadErrorMessage);
        }
      });
    }
  }

  bool get _isManualUpload {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return arguments is Map && arguments['manualUpload'] == true;
  }

  bool get _isExternalShare {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return arguments is Map &&
        arguments[sharedFileExternalUploadArgument] == true;
  }

  AnimalEntity? get _preselectedAnimal {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map && arguments['preselectedAnimal'] is AnimalEntity) {
      return arguments['preselectedAnimal'] as AnimalEntity;
    }
    return null;
  }

  MedicalDocumentCategory? get _requestedCategory {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map &&
        arguments['requestedCategory'] is MedicalDocumentCategory) {
      return arguments['requestedCategory'] as MedicalDocumentCategory;
    }
    return null;
  }

  bool get _shouldResumePending {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return arguments is Map && arguments['resumePending'] == true;
  }

  Future<void> _resumeCompatiblePendingFlow() async {
    if (_pendingResumeChecked) return;
    _pendingResumeChecked = true;
    final flow = context.read<MedicalDocumentFlowCubit>();
    final pending = flow.pendingFlow;
    if (pending == null) return;

    final preselectedAnimal = _preselectedAnimal;
    if (preselectedAnimal != null &&
        !pending.animalIds.contains(preselectedAnimal.id)) {
      return;
    }
    final requestedCategory = _requestedCategory;
    if (requestedCategory != null &&
        pending.requestedCategory != requestedCategory) {
      return;
    }

    final availableAnimals = [
      ...context.read<AnimalCubit>().animals,
      if (preselectedAnimal != null &&
          !context.read<AnimalCubit>().animals.any(
            (animal) => animal.id == preselectedAnimal.id,
          ))
        preselectedAnimal,
    ];
    final restoredAnimals = availableAnimals
        .where((animal) => pending.animalIds.contains(animal.id))
        .toList(growable: false);
    if (restoredAnimals.length != pending.animalIds.length) return;
    setState(() => _selectedAnimals = restoredAnimals);
    await flow.resumePending();
  }

  Future<void> _pickManualFile(ManualFileSource source) async {
    try {
      final file = await context.read<SharedFilesCubit>().pickManualFile(
        source,
      );
      if (!mounted || file == null) return;

      if (!await _discardPendingFlow() || !mounted) return;
      setState(() {
        _manualFile = file;
        _manualFileSelectedAt = DateTime.now();
        _fileNameController.text = file.name;
      });
    } on ManualFileSelectionException catch (error) {
      if (!mounted) return;
      ErrorDisplay.showError(context, error.message);
    } catch (_) {
      if (!mounted) return;
      ErrorDisplay.showError(
        context,
        'No fue posible seleccionar el archivo. Inténtalo nuevamente.',
      );
    }
  }

  Future<void> _onManualFilePickerTap() async {
    if (_manualFile != null) {
      ErrorDisplay.showError(
        context,
        'Solo puedes adjuntar un archivo. Para seleccionar uno diferente, '
        'elimina primero el archivo actual.',
      );
      return;
    }
    final source = await showModalBottomSheet<ManualFileSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.greyBordes,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text('Elegir de Fotos', style: AppTypography.body4),
                onTap: () =>
                    Navigator.pop(sheetContext, ManualFileSource.photos),
              ),
              ListTile(
                leading: SvgPicture.asset(
                  'assets/icons/document-upload.svg',
                  width: 24,
                  height: 24,
                ),
                title: Text('Elegir de Archivos', style: AppTypography.body4),
                onTap: () =>
                    Navigator.pop(sheetContext, ManualFileSource.files),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || source == null) return;
    await _pickManualFile(source);
  }

  Future<void> _removeManualFile() async {
    if (!await _discardPendingFlow() || !mounted) return;
    setState(() {
      _manualFile = null;
      _manualFileSelectedAt = null;
      _fileNameController.clear();
    });
  }

  Future<void> _selectAnimals(List<AnimalEntity> animals) async {
    final selected = await showAnimalSelectionModal(
      context: context,
      animals: animals,
      selectedAnimals: _selectedAnimals,
    );
    if (!mounted || selected == null) return;
    setState(() => _selectedAnimals = selected);
  }

  Future<void> _startAnalysis() async {
    final pendingFiles = context.read<SharedFilesCubit>().pendingFiles;
    final sourceFile = _isManualUpload
        ? _manualFile
        : pendingFiles.isEmpty
        ? null
        : pendingFiles.first;
    if (sourceFile == null || _selectedAnimals.isEmpty) return;
    final flow = context.read<MedicalDocumentFlowCubit>();
    if ((flow.state.remoteDocument != null || flow.pendingFlow != null) &&
        !await _discardPendingFlow()) {
      return;
    }
    if (!mounted) return;
    await flow.startAnalysis(
      file: sourceFile,
      animalIds: _selectedAnimals.map((animal) => animal.id).toList(),
      requestedCategory: _requestedCategory,
    );
  }

  Future<void> _presentReview(MedicalDocumentFlowState state) async {
    if (_reviewPresented || state.remoteDocument == null) return;
    _reviewPresented = true;
    _classificationCancellationConfirmed = false;
    final selected = await showMedicalDocumentClassificationDialog(
      context: context,
      document: state.remoteDocument!,
      initialCategory:
          state.selectedFinalCategory ?? MedicalDocumentCategory.other,
      onProcessCancellationConfirmed: () {
        _classificationCancellationConfirmed = true;
      },
    );
    if (!mounted) return;
    if (selected == null) {
      if (_classificationCancellationConfirmed) {
        _classificationCancellationConfirmed = false;
        await _cancelAndClose();
        return;
      }
      await _discardPendingFlow();
      if (!mounted) return;
      _reviewPresented = false;
      return;
    }
    final flow = context.read<MedicalDocumentFlowCubit>();
    flow.selectFinalCategory(selected);
    final description = _descriptionController.text.trim();
    if (description.isNotEmpty) {
      final draft = flow.state.draftExtraction!;
      flow.updateDraft(
        draft.copyWith(
          additionalFields: {
            ...draft.additionalFields,
            'description': description,
          },
        ),
      );
    }
    final outcome = await Navigator.push<MedicalDocumentReviewOutcome>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: flow,
          child: const MedicalDocumentReviewScreen(),
        ),
      ),
    );
    if (!mounted) return;
    switch (outcome) {
      case MedicalDocumentReviewOutcome.accepted:
        unawaited(_markAiFeedbackPendingForAcceptedDocument(flow.state));
        _reviewPresented = false;
        context.read<SharedFilesCubit>().clear();
        Navigator.pop(
          context,
          _isExternalShare
              ? SharedFileUploadResult(
                  animals: List.unmodifiable(_selectedAnimals),
                  category: flow.state.remoteDocument?.finalCategory,
                )
              : true,
        );
      case MedicalDocumentReviewOutcome.cancelled:
        _reviewPresented = false;
        await _cancelAndClose();
        return;
      case MedicalDocumentReviewOutcome.dismissed:
        final discarded = await flow.discardCurrentFlow(
          showSubmittingState: false,
        );
        if (!discarded) await flow.reset();
        if (!mounted) return;
        _reviewPresented = false;
        if (!discarded) {
          ErrorDisplay.showError(context, sharedFileUploadErrorMessage);
        }
      case MedicalDocumentReviewOutcome.rejected:
        _reviewPresented = false;
      case null:
        _reviewPresented = false;
        break;
    }
  }

  Future<void> _markAiFeedbackPendingForAcceptedDocument(
    MedicalDocumentFlowState state,
  ) async {
    final document = state.remoteDocument;
    final category = document?.finalCategory;
    if (document == null ||
        category == null ||
        !di.sl.isRegistered<MedicalDocumentAiFeedbackLocalDataSource>()) {
      return;
    }

    final store = di.sl<MedicalDocumentAiFeedbackLocalDataSource>();
    try {
      await Future.wait(
        document.animalIds.toSet().map(
          (animalId) => store.markPending(animalId, category),
        ),
      );
    } catch (_) {
      // The document was already accepted; a local feedback prompt failure
      // must not prevent the user from returning to the animal's records.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isManualUpload = _isManualUpload;
    final hasFile = isManualUpload
        ? _manualFile != null
        : _fileNameController.text.isNotEmpty;

    return BlocConsumer<MedicalDocumentFlowCubit, MedicalDocumentFlowState>(
      listenWhen: (previous, current) =>
          previous.phase != current.phase ||
          previous.message != current.message,
      listener: (context, state) {
        if (state.phase == MedicalDocumentFlowPhase.reviewing &&
            !_reviewPresented) {
          _presentReview(state);
        } else if (state.phase == MedicalDocumentFlowPhase.pollingPaused &&
            (state.message?.isNotEmpty ?? false)) {
          ErrorDisplay.showError(context, state.message!);
        } else if (state.phase == MedicalDocumentFlowPhase.failed &&
            (state.message?.isNotEmpty ?? false)) {
          ErrorDisplay.showError(context, sharedFileUploadErrorMessage);
        }
      },
      builder: (context, flowState) => Stack(
        children: [
          ModalPageLayout(
            title: 'Subir archivo',
            fixedTitle: true,
            fixedHeaderHeight: 126,
            titlePadding: const EdgeInsets.only(top: 80, bottom: 12),
            titleStyle: AppTypography.body1.copyWith(
              color: AppColors.greyTextos,
            ),
            onClose: _close,
            bottomSafeAreaColor: AppColors.white,
            bottomPadding: const EdgeInsets.only(left: 24, right: 24, top: 24),
            bottomChild: CustomButton(
              text: switch (flowState.phase) {
                MedicalDocumentFlowPhase.pollingPaused => 'Reanudar análisis',
                MedicalDocumentFlowPhase.reviewing => 'Revisar análisis',
                _ => 'Subir archivo',
              },
              onPressed:
                  !hasFile || _selectedAnimals.isEmpty || flowState.isBusy
                  ? null
                  : switch (flowState.phase) {
                      MedicalDocumentFlowPhase.pollingPaused =>
                        () => context
                            .read<MedicalDocumentFlowCubit>()
                            .resumePolling(),
                      MedicalDocumentFlowPhase.reviewing => _startAnalysis,
                      _ => _startAnalysis,
                    },
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isManualUpload) ...[
                    _ManualFilePicker(
                      hasSelectedFile: _manualFile != null,
                      onTap: _onManualFilePickerTap,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    if (_manualFile case final file?) ...[
                      _SelectedManualFile(
                        file: file,
                        selectedAt: _manualFileSelectedAt ?? DateTime.now(),
                        onDelete: _removeManualFile,
                      ),
                      const SizedBox(height: AppSpacing.m),
                    ],
                  ] else ...[
                    Text(
                      'Los archivos cargados estarán disponibles en la sección '
                      'correspondiente a su tipo de archivo.',
                      style: AppTypography.body4.copyWith(
                        color: AppColors.greyTextos,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    CustomTextField(
                      label: 'Nombre del archivo',
                      controller: _fileNameController,
                      enabled: false,
                      labelStyle: AppTypography.body6.copyWith(
                        color: AppColors.greyTextos.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                  ],
                  if (_preselectedAnimal != null)
                    AppDropdown<AnimalEntity>(
                      label: 'Animal',
                      hint: '',
                      value: _preselectedAnimal,
                      items: [_preselectedAnimal!],
                      itemAsString: (animal) => animal.name,
                      enabled: false,
                      onChanged: null,
                    )
                  else
                    BlocBuilder<AnimalCubit, AnimalState>(
                      builder: (context, state) {
                        final cubit = context.read<AnimalCubit>();
                        final animals = cubit.animals
                            .where((animal) => animal.isActive)
                            .toList(growable: false);
                        return AppMultiSearchDropdown<AnimalEntity>(
                          label: 'Animal(es)',
                          hint: state is AnimalsLoading
                              ? 'Cargando animales...'
                              : 'Seleccione el animal o animales',
                          selectedItems: _selectedAnimals,
                          items: animals,
                          itemAsString: (animal) => animal.name,
                          enabled: state is! AnimalsLoading,
                          searchable: false,
                          pushContentDown: false,
                          onTap: () {
                            _selectAnimals(animals);
                          },
                          onChanged: (animals) {
                            setState(() => _selectedAnimals = animals);
                          },
                        );
                      },
                    ),
                  const SizedBox(height: AppSpacing.m),
                  CustomTextField(
                    label: 'Descripción (Opcional)',
                    controller: _descriptionController,
                    maxLength: 50,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
          if (flowState.phase == MedicalDocumentFlowPhase.uploading ||
              flowState.phase == MedicalDocumentFlowPhase.analyzing)
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.white.withValues(alpha: 0.72),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.aiViolet,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        'Analizando archivo...',
                        style: AppTypography.body4.copyWith(
                          color: AppColors.aiViolet,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ManualFilePicker extends StatelessWidget {
  final bool hasSelectedFile;
  final VoidCallback onTap;

  const _ManualFilePicker({required this.hasSelectedFile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Seleccionar archivo o imagen',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: CustomPaint(
          foregroundPainter: _DashedRoundedBorderPainter(
            color: hasSelectedFile
                ? AppColors.greyBordes
                : AppColors.primaryAzulClaro,
          ),
          child: Container(
            width: double.infinity,
            height: 169,
            decoration: BoxDecoration(
              color: AppColors.bgBlancoAntiFlash,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/document-upload.svg',
                  width: AppSpacing.iconSizeSmall,
                  height: AppSpacing.iconSizeSmall,
                  colorFilter: ColorFilter.mode(
                    hasSelectedFile
                        ? AppColors.greyBordes
                        : AppColors.primaryAzulClaro,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pulsa aquí para subir un archivo o imagen',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.body3.copyWith(
                    color: AppColors.greyTextos,
                  ),
                ),
                Text(
                  'PNG, JPG, JPEG o TIFF',
                  style: AppTypography.body6.copyWith(
                    color: AppColors.greyBordes,
                  ),
                ),
                Text(
                  'Archivos de hasta 10 MB',
                  style: AppTypography.body6.copyWith(
                    color: AppColors.greyBordes,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedManualFile extends StatelessWidget {
  final SharedFileEntity file;
  final DateTime selectedAt;
  final VoidCallback onDelete;

  const _SelectedManualFile({
    required this.file,
    required this.selectedAt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 73,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.greyDelineante, width: 1),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(width: 60, height: 40, child: _buildThumbnail()),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body3.copyWith(
                    color: AppColors.greyNegro,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _formattedSize,
                      style: AppTypography.body6.copyWith(
                        color: AppColors.greyBordes,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        _formattedDateTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body6.copyWith(
                          color: AppColors.greyTextos,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          SizedBox(
            width: 40,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: SvgPicture.asset(
                    'assets/icons/icon_trash.svg',
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(
                      AppColors.errorRojo,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    if (file.type == SharedFileType.image) {
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        return Image.memory(
          file.bytes!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPathThumbnail(),
        );
      }
      return _buildPathThumbnail();
    }
    if (file.type == SharedFileType.pdf) {
      return ColoredBox(
        color: AppColors.white,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: SvgPicture.asset(
            'assets/icons/PDF.svg',
            fit: BoxFit.contain,
          ),
        ),
      );
    }
    return _fallbackThumbnail();
  }

  Widget _buildPathThumbnail() {
    if (file.path.isEmpty) return _fallbackThumbnail();
    if (kIsWeb) {
      return Image.network(
        file.path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackThumbnail(),
      );
    }
    if (io.File(file.path).existsSync()) {
      return Image.file(
        io.File(file.path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackThumbnail(),
      );
    }
    return _fallbackThumbnail();
  }

  Widget _fallbackThumbnail() {
    return ColoredBox(
      color: const Color(0xFFD9D9D9),
      child: Center(
        child: SvgPicture.asset(
          'assets/icons/document-upload.svg',
          width: AppSpacing.iconSizeSmall,
          height: AppSpacing.iconSizeSmall,
          colorFilter: const ColorFilter.mode(
            AppColors.greyBordes,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  String get _formattedSize {
    final megabytes = file.size / (1024 * 1024);
    final value = megabytes == megabytes.roundToDouble()
        ? megabytes.toStringAsFixed(0)
        : megabytes.toStringAsFixed(1);
    return '$value Mb';
  }

  String get _formattedDateTime {
    final now = DateTime.now();
    final isToday =
        selectedAt.year == now.year &&
        selectedAt.month == now.month &&
        selectedAt.day == now.day;
    final date = isToday
        ? 'Hoy'
        : '${selectedAt.day.toString().padLeft(2, '0')}/'
              '${selectedAt.month.toString().padLeft(2, '0')}/'
              '${selectedAt.year}';
    final hour = selectedAt.hour % 12 == 0 ? 12 : selectedAt.hour % 12;
    final minute = selectedAt.minute.toString().padLeft(2, '0');
    final period = selectedAt.hour >= 12 ? 'p.m.' : 'a.m.';
    return '$date $hour:$minute $period';
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedRoundedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
          const Radius.circular(4),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + 7 < metric.length ? distance + 7 : metric.length;
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
