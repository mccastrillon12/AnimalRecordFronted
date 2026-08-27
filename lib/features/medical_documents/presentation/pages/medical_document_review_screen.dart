import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/medical_document_flow_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/medical_document_flow_state.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_pdf_adapter.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_original_preview.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_rejection_dialog.dart';
import 'package:animal_record/features/shared_files/presentation/pages/shared_file_analysis_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum MedicalDocumentReviewOutcome { accepted, cancelled, dismissed, rejected }

/// Adapts the medical-document state to the existing analysis design.
/// Backend flow and UI remain separated: this page only coordinates them.
class MedicalDocumentReviewScreen extends StatefulWidget {
  const MedicalDocumentReviewScreen({super.key});

  @override
  State<MedicalDocumentReviewScreen> createState() =>
      _MedicalDocumentReviewScreenState();
}

class _MedicalDocumentReviewScreenState
    extends State<MedicalDocumentReviewScreen> {
  late final MedicalDocumentOriginalPreview _originalPreview;
  final _reviewCloseIconKey = GlobalKey();
  final _sendCloseIconKey = GlobalKey();
  final _sendActionIconKey = GlobalKey();
  bool _completionHandled = false;
  bool _canPop = false;
  bool _isDiscarding = false;
  bool _showCancellationOverlay = false;

  @override
  void initState() {
    super.initState();
    _originalPreview = MedicalDocumentOriginalPreview(
      getDownloadUriUseCase: di.sl<GetMedicalDocumentDownloadUriUseCase>(),
      saveOriginalUseCase: di.sl<SaveMedicalDocumentOriginalUseCase>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _discardAndClose();
      },
      child: BlocConsumer<MedicalDocumentFlowCubit, MedicalDocumentFlowState>(
        listenWhen: (previous, current) =>
            previous.message != current.message ||
            previous.phase != current.phase,
        listener: (context, state) {
          if (state.message?.isNotEmpty ?? false) {
            ErrorDisplay.showError(context, state.message!);
          }
          if (state.phase == MedicalDocumentFlowPhase.rejected) {
            _popWithResult(MedicalDocumentReviewOutcome.rejected);
          }
          if (state.phase == MedicalDocumentFlowPhase.completed) {
            _showAcceptedDocument(state);
          }
        },
        builder: (context, state) {
          final document = state.remoteDocument;
          final extraction = state.draftExtraction;
          if (document == null || extraction == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return Stack(
            children: [
              SharedFileAnalysisReviewScreen(
                analysis: medicalDocumentToAnalysis(
                  document: document,
                  extraction: extraction,
                ),
                isSubmitting:
                    state.phase == MedicalDocumentFlowPhase.submitting,
                onSubmit: () =>
                    context.read<MedicalDocumentFlowCubit>().accept(),
                onDoNotUpload: _showRejectionDialog,
                onViewOriginal: () => _showOriginal(_reviewCloseIconKey),
                onClose: _discardAndClose,
                closeIconKey: _reviewCloseIconKey,
              ),
              if (_showCancellationOverlay) ...[
                const Positioned.fill(
                  child: ModalBarrier(
                    dismissible: false,
                    color: AppColors.overlayBlack,
                  ),
                ),
                const Positioned.fill(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.white),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _discardAndClose() {
    if (_isDiscarding) return;
    _isDiscarding = true;
    _popWithResult(MedicalDocumentReviewOutcome.dismissed);
  }

  Future<void> _showRejectionDialog() async {
    var cancelRequested = false;
    final reason = await showMedicalDocumentRejectionDialog(
      context: context,
      loadReasons: di.sl<GetMedicalDocumentRejectionReasonsUseCase>(),
      onCancel: () async {
        cancelRequested = true;
        if (!mounted) return;
        setState(() => _showCancellationOverlay = true);
        await _discardForCancellation();
      },
    );
    if (!mounted) return;
    if (cancelRequested) {
      _popWithResult(MedicalDocumentReviewOutcome.cancelled);
      return;
    }
    if (reason == null) return;
    await context.read<MedicalDocumentFlowCubit>().reject(
      reasonCode: reason.reason.code,
      comment: reason.comment,
    );
  }

  Future<void> _discardForCancellation() async {
    if (_isDiscarding) return;
    _isDiscarding = true;
    await context.read<MedicalDocumentFlowCubit>().discardCurrentFlow(
      showSubmittingState: false,
      resetStateAfterDiscard: false,
    );
    if (!mounted) return;
    _isDiscarding = false;
  }

  void _popWithResult(MedicalDocumentReviewOutcome result) {
    if (!mounted) return;
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop<MedicalDocumentReviewOutcome>(context, result);
    });
  }

  Future<void> _showAcceptedDocument(MedicalDocumentFlowState state) async {
    if (_completionHandled) return;
    _completionHandled = true;
    final document = state.remoteDocument;
    if (document == null ||
        document.finalCategory != MedicalDocumentCategory.prescription ||
        document.validatedExtraction == null) {
      if (mounted) _popWithResult(MedicalDocumentReviewOutcome.accepted);
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SharedFileSendScreen(
          analysis: medicalDocumentToPdfAnalysis(document: document),
          closeIconKey: _sendCloseIconKey,
          actionIconKey: _sendActionIconKey,
          onViewOriginal: () => _showOriginal(
            _sendCloseIconKey,
            downloadIconKey: _sendActionIconKey,
          ),
          resolveOriginalUri: () =>
              di.sl<GetMedicalDocumentDownloadUriUseCase>()(document.id),
          actionLabel: medicalDocumentSendActionLabel(
            document.finalCategory ?? MedicalDocumentCategory.prescription,
          ),
        ),
      ),
    );
    if (mounted) _popWithResult(MedicalDocumentReviewOutcome.accepted);
  }

  Future<void> _showOriginal(
    GlobalKey closeIconKey, {
    GlobalKey? downloadIconKey,
  }) async {
    final state = context.read<MedicalDocumentFlowCubit>().state;
    final document = state.remoteDocument!;
    try {
      await _originalPreview.show(
        context,
        localFile: state.sourceFile,
        acceptedDocumentId: document.status == MedicalDocumentStatus.accepted
            ? document.id
            : null,
        fileName: document.originalFileName,
        mimeType: document.mimeType,
        closeIconKey: closeIconKey,
        downloadIconKey: downloadIconKey,
      );
    } catch (error) {
      if (mounted) ErrorDisplay.showError(context, error.toString());
    }
  }
}
