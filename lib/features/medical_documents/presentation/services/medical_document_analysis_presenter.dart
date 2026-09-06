import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_pdf_adapter.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';

/// Coordinates asynchronous catalog loading with the pure analysis mapper.
/// Keeping this outside widgets makes the same presentation contract reusable
/// by review, accepted-document details and PDF export.
class MedicalDocumentAnalysisPresenter {
  final GetMedicalFieldCatalogUseCase getFieldCatalog;

  const MedicalDocumentAnalysisPresenter({required this.getFieldCatalog});

  Future<SharedFileAnalysisEntity> forReview({
    required MedicalDocumentEntity document,
    required MedicalDocumentExtractionEntity extraction,
    required MedicalDocumentCategory finalCategory,
  }) async {
    final catalog = await getFieldCatalog(category: extraction.documentType);
    return medicalDocumentToAnalysis(
      document: document,
      extraction: extraction,
      catalog: catalog,
      displayCategory: finalCategory,
      includeUncataloguedFields: finalCategory != extraction.documentType,
    );
  }

  Future<SharedFileAnalysisEntity> forAccepted(
    MedicalDocumentEntity document,
  ) async {
    final extraction = document.validatedExtraction;
    if (extraction == null) {
      throw const FormatException(
        'El documento no contiene una extracción validada.',
      );
    }
    final catalog = await getFieldCatalog(category: extraction.documentType);
    return medicalDocumentToPdfAnalysis(document: document, catalog: catalog);
  }
}
