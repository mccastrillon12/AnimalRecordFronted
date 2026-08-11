import 'package:animal_record/core/injection_container.dart' as di;
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
  bool _completionHandled = false;
  bool _canPop = false;
  bool _isDiscarding = false;

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
            _popWithResult(false);
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
          return SharedFileAnalysisReviewScreen(
            analysis: medicalDocumentToAnalysis(
              document: document,
              extraction: extraction,
            ),
            isSubmitting: state.phase == MedicalDocumentFlowPhase.submitting,
            onSubmit: () => context.read<MedicalDocumentFlowCubit>().accept(),
            onDoNotUpload: _showRejectionDialog,
            onViewOriginal: _showOriginal,
            onClose: _discardAndClose,
          );
        },
      ),
    );
  }

  Future<void> _discardAndClose() async {
    if (_isDiscarding) return;
    _isDiscarding = true;
    final discarded = await context
        .read<MedicalDocumentFlowCubit>()
        .discardCurrentFlow();
    if (!mounted) return;
    _isDiscarding = false;
    if (discarded) _popWithResult(false);
  }

  Future<void> _showRejectionDialog() async {
    final reason = await showMedicalDocumentRejectionDialog(context: context);
    if (!mounted || reason == null) return;
    await context.read<MedicalDocumentFlowCubit>().reject();
  }

  void _popWithResult(bool result) {
    if (!mounted) return;
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, result);
    });
  }

  Future<void> _showAcceptedDocument(MedicalDocumentFlowState state) async {
    if (_completionHandled) return;
    _completionHandled = true;
    final document = state.remoteDocument;
    if (document == null ||
        document.finalCategory != MedicalDocumentCategory.prescription ||
        document.validatedExtraction == null) {
      if (mounted) _popWithResult(true);
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SharedFileSendScreen(
          analysis: medicalDocumentToPdfAnalysis(document: document),
          onViewOriginal: _showOriginal,
          resolveOriginalUri: () =>
              di.sl<GetMedicalDocumentDownloadUriUseCase>()(document.id),
          actionLabel: medicalDocumentSendActionLabel(
            document.finalCategory ?? MedicalDocumentCategory.prescription,
          ),
        ),
      ),
    );
    if (mounted) _popWithResult(true);
  }

  Future<void> _showOriginal() async {
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
      );
    } catch (error) {
      if (mounted) ErrorDisplay.showError(context, error.toString());
    }
  }
}
