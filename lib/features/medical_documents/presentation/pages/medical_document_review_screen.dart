import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/widgets/feedback/process_cancellation_dialog.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/medical_document_flow_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/medical_document_flow_state.dart';
import 'package:animal_record/features/medical_documents/presentation/services/medical_document_analysis_presenter.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_original_preview.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_rejection_dialog.dart';
import 'package:animal_record/features/shared_files/presentation/pages/shared_file_analysis_review_screen.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
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
  bool _completionHandled = false;
  bool _canPop = false;
  bool _isDiscarding = false;
  MedicalDocumentExtractionEntity? _analysisExtraction;
  Future<SharedFileAnalysisEntity>? _analysisFuture;

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
            _finishAcceptedDocument();
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
          return FutureBuilder<SharedFileAnalysisEntity>(
            future: _analysisFor(document, extraction),
            builder: (context, snapshot) {
              final analysis = snapshot.data;
              if (snapshot.connectionState != ConnectionState.done) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (analysis == null) {
                return _CatalogLoadError(onRetry: _retryCatalog);
              }
              return SharedFileAnalysisReviewScreen(
                analysis: analysis,
                isSubmitting:
                    state.phase == MedicalDocumentFlowPhase.submitting,
                onSubmit: () =>
                    context.read<MedicalDocumentFlowCubit>().accept(),
                onDoNotUpload: _showRejectionDialog,
                onViewOriginal: () => _showOriginal(_reviewCloseIconKey),
                onClose: _discardAndClose,
                closeIconKey: _reviewCloseIconKey,
              );
            },
          );
        },
      ),
    );
  }

  Future<SharedFileAnalysisEntity> _analysisFor(
    MedicalDocumentEntity document,
    MedicalDocumentExtractionEntity extraction,
  ) {
    if (!identical(_analysisExtraction, extraction) ||
        _analysisFuture == null) {
      _analysisExtraction = extraction;
      _analysisFuture = di.sl<MedicalDocumentAnalysisPresenter>().forReview(
        document: document,
        extraction: extraction,
      );
    }
    return _analysisFuture!;
  }

  void _retryCatalog() {
    setState(() => _analysisFuture = null);
  }

  Future<void> _discardAndClose() async {
    if (_isDiscarding) return;
    _isDiscarding = true;
    final confirmed = await showProcessCancellationDialog(context);
    if (!mounted) return;
    if (confirmed) {
      _popWithResult(MedicalDocumentReviewOutcome.cancelled);
    } else {
      _isDiscarding = false;
    }
  }

  Future<void> _showRejectionDialog() async {
    final reason = await showMedicalDocumentRejectionDialog(
      context: context,
      loadReasons: di.sl<GetMedicalDocumentRejectionReasonsUseCase>(),
    );
    if (!mounted) return;
    if (reason == null) return;
    await context.read<MedicalDocumentFlowCubit>().reject(
      reasonCode: reason.reason.code,
      comment: reason.comment,
    );
  }

  void _popWithResult(MedicalDocumentReviewOutcome result) {
    if (!mounted) return;
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop<MedicalDocumentReviewOutcome>(context, result);
    });
  }

  void _finishAcceptedDocument() {
    if (_completionHandled) return;
    _completionHandled = true;
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

class _CatalogLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _CatalogLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No pudimos cargar los campos del documento.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ),
        ),
      ),
    );
  }
}
