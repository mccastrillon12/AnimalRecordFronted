import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';

class MedicalDocumentContractException implements Exception {
  final String message;

  const MedicalDocumentContractException(this.message);

  @override
  String toString() => message;
}

abstract final class MedicalDocumentContractValidator {
  static const maximumFileSize = 10 * 1024 * 1024;
  static const supportedMimeTypes = {
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/tiff',
  };
  static final _uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static void validateAnalysis({
    required SharedFileEntity file,
    required List<String> animalIds,
  }) {
    if (animalIds.isEmpty) {
      throw const MedicalDocumentContractException(
        'Selecciona al menos un animal.',
      );
    }
    if (animalIds.toSet().length != animalIds.length ||
        animalIds.any((id) => !_uuidV4.hasMatch(id))) {
      throw const MedicalDocumentContractException(
        'La selección contiene identificadores de animales inválidos.',
      );
    }
    if (!supportedMimeTypes.contains(file.mimeType.toLowerCase())) {
      throw const MedicalDocumentContractException(
        'Selecciona un archivo PDF, JPEG, PNG o TIFF.',
      );
    }
    if (file.size > maximumFileSize) {
      throw const MedicalDocumentContractException(
        'El archivo debe pesar máximo 10 MB.',
      );
    }
    final hasBytes = file.bytes?.isNotEmpty == true;
    if (!hasBytes && file.path.trim().isEmpty) {
      throw const MedicalDocumentContractException(
        'El archivo seleccionado está vacío.',
      );
    }
  }

  static void validateReview({
    required ReviewMedicalDocumentRequest request,
    required List<String> originalAnimalIds,
  }) {
    if (request.documentVersion < 1) {
      throw const MedicalDocumentContractException(
        'No se recibió una versión válida del archivo.',
      );
    }
    if (request.decision == MedicalDocumentReviewDecision.reject) return;

    final category = request.finalCategory;
    final extraction = request.validatedExtraction;
    if (category == null || extraction == null) {
      throw const MedicalDocumentContractException(
        'La categoría final y la extracción validada son obligatorias.',
      );
    }
    if (extraction.documentType != category) {
      throw const MedicalDocumentContractException(
        'La extracción validada no corresponde a la categoría final.',
      );
    }
    if (_hasDisallowedCategoryData(extraction, category)) {
      throw const MedicalDocumentContractException(
        'La extracción validada mezcla información de categorías diferentes.',
      );
    }

    final itemIds = extraction.extractedItemIds;
    if (itemIds.any((id) => id.trim().isEmpty) ||
        itemIds.toSet().length != itemIds.length) {
      throw const MedicalDocumentContractException(
        'Los elementos extraídos deben tener identificadores únicos.',
      );
    }

    final expectedAnimals = originalAnimalIds.toSet();
    final assignedAnimals = request.assignments
        .map((assignment) => assignment.animalId)
        .toList(growable: false);
    if (assignedAnimals.length != originalAnimalIds.length ||
        assignedAnimals.toSet().length != assignedAnimals.length ||
        assignedAnimals.toSet().difference(expectedAnimals).isNotEmpty ||
        expectedAnimals.difference(assignedAnimals.toSet()).isNotEmpty) {
      throw const MedicalDocumentContractException(
        'Debe existir exactamente una asignación por cada animal.',
      );
    }

    final validItemIds = itemIds.toSet();
    for (final assignment in request.assignments) {
      if (assignment.extractedItemIds.toSet().length !=
              assignment.extractedItemIds.length ||
          assignment.extractedItemIds.any(
            (itemId) => !validItemIds.contains(itemId),
          )) {
        throw const MedicalDocumentContractException(
          'Las asignaciones contienen elementos inexistentes o duplicados.',
        );
      }
    }
  }

  static bool _hasDisallowedCategoryData(
    MedicalDocumentExtractionEntity extraction,
    MedicalDocumentCategory category,
  ) {
    final diagnosesAllowed = switch (category) {
      MedicalDocumentCategory.prescription ||
      MedicalDocumentCategory.medicalOrder ||
      MedicalDocumentCategory.referral ||
      MedicalDocumentCategory.clinicalHistory => true,
      _ => false,
    };
    final medicationsAllowed =
        category == MedicalDocumentCategory.prescription ||
        category == MedicalDocumentCategory.referral;
    final diagnosticResultsAllowed =
        category == MedicalDocumentCategory.referral ||
        category == MedicalDocumentCategory.clinicalHistory;

    return (!diagnosesAllowed && extraction.diagnoses.isNotEmpty) ||
        (!medicationsAllowed && extraction.medications.isNotEmpty) ||
        (category != MedicalDocumentCategory.vaccinationCard &&
            extraction.vaccinations.isNotEmpty) ||
        (category != MedicalDocumentCategory.medicalOrder &&
            extraction.medicalOrders.isNotEmpty) ||
        (category != MedicalDocumentCategory.clinicalHistory &&
            extraction.clinicalHistory != null) ||
        (!diagnosticResultsAllowed &&
            extraction.diagnosticResults.isNotEmpty) ||
        (category != MedicalDocumentCategory.referral &&
            extraction.referral != null);
  }
}
