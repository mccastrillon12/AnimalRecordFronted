import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';

const sharedFileReturnUploadResultArgument = 'returnUploadResult';

class SharedFileUploadResult {
  final List<AnimalEntity> animals;
  final MedicalDocumentCategory? category;

  const SharedFileUploadResult({required this.animals, required this.category});

  AnimalEntity? get singleAnimal => animals.length == 1 ? animals.single : null;
}

class SharedFileUploadDestination {
  final AnimalModel animal;
  final String? sectionRouteName;
  final Object? sectionArguments;

  const SharedFileUploadDestination({
    required this.animal,
    this.sectionRouteName,
    this.sectionArguments,
  });
}

SharedFileUploadDestination? resolveSharedFileUploadDestination(
  SharedFileUploadResult result,
) {
  final animal = result.singleAnimal;
  final category = result.category;
  if (animal == null || category == null) return null;

  final animalModel = AnimalModel.fromEntity(animal);
  return switch (category) {
    MedicalDocumentCategory.prescription ||
    MedicalDocumentCategory.medicalOrder ||
    MedicalDocumentCategory.referral => SharedFileUploadDestination(
      animal: animalModel,
      sectionRouteName: AppRoutes.animalDocuments,
      sectionArguments: {'animalId': animal.id, 'initialCategory': category},
    ),
    MedicalDocumentCategory.vaccinationCard => SharedFileUploadDestination(
      animal: animalModel,
      sectionRouteName: AppRoutes.animalVaccinations,
      sectionArguments: animalModel,
    ),
    MedicalDocumentCategory.clinicalHistory => SharedFileUploadDestination(
      animal: animalModel,
      sectionRouteName: AppRoutes.animalClinicalHistory,
      sectionArguments: animalModel,
    ),
    MedicalDocumentCategory.diagnosticImage => SharedFileUploadDestination(
      animal: animalModel,
      sectionRouteName: AppRoutes.animalDiagnosticImages,
      sectionArguments: animalModel,
    ),
    MedicalDocumentCategory.laboratoryResult => SharedFileUploadDestination(
      animal: animalModel,
      sectionRouteName: AppRoutes.animalLaboratoryResults,
      sectionArguments: animalModel,
    ),
    MedicalDocumentCategory.other => SharedFileUploadDestination(
      animal: animalModel,
    ),
  };
}
