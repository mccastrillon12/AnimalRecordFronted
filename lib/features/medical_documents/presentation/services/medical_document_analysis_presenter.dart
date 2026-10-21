import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_pdf_adapter.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_display_formatter.dart';
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
    SharedFilePatientAnalysisEntity? appPatient,
    SharedFileTutorAnalysisEntity? appTutor,
  }) async {
    final catalog = await getFieldCatalog(category: extraction.documentType);
    final analysis = medicalDocumentToAnalysis(
      document: document,
      extraction: extraction,
      catalog: catalog,
      displayCategory: finalCategory,
      includeUncataloguedFields: finalCategory != extraction.documentType,
    );
    return _withAppData(
      analysis,
      extraction: extraction,
      appPatient: appPatient,
      appTutor: appTutor,
    );
  }

  Future<SharedFileAnalysisEntity> forAccepted(
    MedicalDocumentEntity document, {
    SharedFilePatientAnalysisEntity? appPatient,
    SharedFileTutorAnalysisEntity? appTutor,
  }) async {
    final extraction = document.validatedExtraction;
    if (extraction == null) {
      throw const FormatException(
        'El documento no contiene una extracción validada.',
      );
    }
    final catalog = await getFieldCatalog(category: extraction.documentType);
    final analysis = medicalDocumentToPdfAnalysis(
      document: document,
      catalog: catalog,
    );
    return _withAppData(
      analysis,
      extraction: extraction,
      appPatient: appPatient,
      appTutor: appTutor,
    );
  }

  SharedFileAnalysisEntity _withAppData(
    SharedFileAnalysisEntity analysis, {
    required MedicalDocumentExtractionEntity extraction,
    SharedFilePatientAnalysisEntity? appPatient,
    SharedFileTutorAnalysisEntity? appTutor,
  }) {
    final patient = appPatient == null
        ? null
        : SharedFilePatientAnalysisEntity(
            name: appPatient.name,
            recordId: appPatient.recordId,
            species: appPatient.species,
            breed: appPatient.breed,
            sex: appPatient.sex,
            color: appPatient.color,
            age: appPatient.age,
            weight: _documentWeight(extraction) ?? appPatient.weight,
            additionalDetails: appPatient.additionalDetails,
          );
    return analysis.withPdfProfile(patient: patient, tutor: appTutor);
  }

  String? _documentWeight(MedicalDocumentExtractionEntity extraction) {
    final patient = extraction.patient;
    if (patient == null) return null;
    final values = [patient.fields['weight'], patient.weight];
    for (final value in values) {
      final formatted = medicalDocumentDisplayValue(value).trim();
      if (formatted.isNotEmpty) return formatted;
    }
    return null;
  }
}
