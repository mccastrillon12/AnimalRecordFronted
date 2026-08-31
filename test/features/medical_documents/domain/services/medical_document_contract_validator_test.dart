import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_contract_validator.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const animal1 = '11111111-1111-4111-8111-111111111111';
  const animal2 = '22222222-2222-4222-8222-222222222222';
  const file = SharedFileEntity(
    path: '/tmp/document.pdf',
    name: 'document.pdf',
    mimeType: 'application/pdf',
    type: SharedFileType.pdf,
    size: 1024,
  );

  test('accepts a supported file and unique UUID v4 animal ids', () {
    expect(
      () => MedicalDocumentContractValidator.validateAnalysis(
        file: file,
        animalIds: const [animal1, animal2],
      ),
      returnsNormally,
    );
  });

  test('rejects invalid or duplicated animal ids before upload', () {
    expect(
      () => MedicalDocumentContractValidator.validateAnalysis(
        file: file,
        animalIds: const ['animal-1'],
      ),
      throwsA(isA<MedicalDocumentContractException>()),
    );
    expect(
      () => MedicalDocumentContractValidator.validateAnalysis(
        file: file,
        animalIds: const [animal1, animal1],
      ),
      throwsA(isA<MedicalDocumentContractException>()),
    );
  });

  test('rejects unsupported, oversized and empty upload files', () {
    final invalidFiles = [
      const SharedFileEntity(
        path: '/tmp/document.txt',
        name: 'document.txt',
        mimeType: 'text/plain',
        type: SharedFileType.unsupported,
        size: 10,
      ),
      const SharedFileEntity(
        path: '/tmp/document.pdf',
        name: 'document.pdf',
        mimeType: 'application/pdf',
        type: SharedFileType.pdf,
        size: MedicalDocumentContractValidator.maximumFileSize + 1,
      ),
      const SharedFileEntity(
        path: '',
        name: 'document.pdf',
        mimeType: 'application/pdf',
        type: SharedFileType.pdf,
      ),
    ];

    for (final invalidFile in invalidFiles) {
      expect(
        () => MedicalDocumentContractValidator.validateAnalysis(
          file: invalidFile,
          animalIds: const [animal1],
        ),
        throwsA(isA<MedicalDocumentContractException>()),
      );
    }
  });

  test('requires one valid assignment per original animal', () {
    final request = ReviewMedicalDocumentRequest.accept(
      documentVersion: 2,
      finalCategory: MedicalDocumentCategory.prescription,
      validatedExtraction: const MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.prescription,
        medications: [
          MedicalDocumentItemEntity(
            id: 'medication-1',
            fields: {'name': 'Medicine'},
          ),
        ],
      ),
      assignments: const [
        MedicalDocumentAssignmentEntity(
          animalId: animal1,
          extractedItemIds: ['medication-1'],
        ),
      ],
    );

    expect(
      () => MedicalDocumentContractValidator.validateReview(
        request: request,
        originalAnimalIds: const [animal1, animal2],
      ),
      throwsA(isA<MedicalDocumentContractException>()),
    );
  });

  test('rejects duplicated item ids across extraction sections', () {
    final request = ReviewMedicalDocumentRequest.accept(
      documentVersion: 2,
      finalCategory: MedicalDocumentCategory.referral,
      validatedExtraction: const MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.referral,
        diagnoses: [MedicalDocumentItemEntity(id: 'same-id')],
        medications: [MedicalDocumentItemEntity(id: 'same-id')],
      ),
      assignments: const [
        MedicalDocumentAssignmentEntity(animalId: animal1),
        MedicalDocumentAssignmentEntity(animalId: animal2),
      ],
    );

    expect(
      () => MedicalDocumentContractValidator.validateReview(
        request: request,
        originalAnimalIds: const [animal1, animal2],
      ),
      throwsA(isA<MedicalDocumentContractException>()),
    );
  });

  test('rejects structured sections from another final category', () {
    final request = ReviewMedicalDocumentRequest.accept(
      documentVersion: 2,
      finalCategory: MedicalDocumentCategory.vaccinationCard,
      validatedExtraction: const MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.vaccinationCard,
        medications: [MedicalDocumentItemEntity(id: 'medication-1')],
      ),
      assignments: const [
        MedicalDocumentAssignmentEntity(animalId: animal1),
        MedicalDocumentAssignmentEntity(animalId: animal2),
      ],
    );

    expect(
      () => MedicalDocumentContractValidator.validateReview(
        request: request,
        originalAnimalIds: const [animal1, animal2],
      ),
      throwsA(isA<MedicalDocumentContractException>()),
    );
  });

  test(
    'keeps diagnostic images and laboratory results in their own categories',
    () {
      final diagnosticImageRequest = ReviewMedicalDocumentRequest.accept(
        documentVersion: 2,
        finalCategory: MedicalDocumentCategory.diagnosticImage,
        validatedExtraction: const MedicalDocumentExtractionEntity(
          documentType: MedicalDocumentCategory.diagnosticImage,
          diagnosticImages: [
            MedicalDocumentItemEntity(id: 'image-1', fields: {'name': 'RX'}),
          ],
        ),
        assignments: const [
          MedicalDocumentAssignmentEntity(
            animalId: animal1,
            extractedItemIds: ['image-1'],
          ),
          MedicalDocumentAssignmentEntity(animalId: animal2),
        ],
      );
      final laboratoryRequest = ReviewMedicalDocumentRequest.accept(
        documentVersion: 2,
        finalCategory: MedicalDocumentCategory.laboratoryResult,
        validatedExtraction: const MedicalDocumentExtractionEntity(
          documentType: MedicalDocumentCategory.laboratoryResult,
          laboratoryReport: {
            'reportedComments': ['* Resultado confirmado'],
          },
          laboratoryResults: [
            MedicalDocumentItemEntity(
              id: 'laboratory-result-1',
              fields: {'name': 'Urea', 'result': '15', 'flag': '*'},
            ),
          ],
        ),
        assignments: const [
          MedicalDocumentAssignmentEntity(
            animalId: animal1,
            extractedItemIds: ['laboratory-result-1'],
          ),
          MedicalDocumentAssignmentEntity(animalId: animal2),
        ],
      );

      expect(
        () => MedicalDocumentContractValidator.validateReview(
          request: diagnosticImageRequest,
          originalAnimalIds: const [animal1, animal2],
        ),
        returnsNormally,
      );
      expect(
        () => MedicalDocumentContractValidator.validateReview(
          request: laboratoryRequest,
          originalAnimalIds: const [animal1, animal2],
        ),
        returnsNormally,
      );
    },
  );

  test('rejects laboratory fields mixed into another final category', () {
    final request = ReviewMedicalDocumentRequest.accept(
      documentVersion: 2,
      finalCategory: MedicalDocumentCategory.diagnosticImage,
      validatedExtraction: const MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.diagnosticImage,
        diagnosticImages: [MedicalDocumentItemEntity(id: 'image-1')],
        laboratoryResults: [MedicalDocumentItemEntity(id: 'result-1')],
      ),
      assignments: const [
        MedicalDocumentAssignmentEntity(animalId: animal1),
        MedicalDocumentAssignmentEntity(animalId: animal2),
      ],
    );

    expect(
      () => MedicalDocumentContractValidator.validateReview(
        request: request,
        originalAnimalIds: const [animal1, animal2],
      ),
      throwsA(isA<MedicalDocumentContractException>()),
    );
  });

  test('requires a backend rejection reason and comment for OTHER', () {
    final withoutReason = ReviewMedicalDocumentRequest.reject(
      documentVersion: 2,
    );
    final otherWithoutComment = ReviewMedicalDocumentRequest.reject(
      documentVersion: 2,
      rejectionReasonCode: 'OTHER',
    );
    final valid = ReviewMedicalDocumentRequest.reject(
      documentVersion: 2,
      rejectionReasonCode: 'OTHER',
      rejectionComment: 'El archivo no corresponde al animal.',
    );

    expect(
      () => MedicalDocumentContractValidator.validateReview(
        request: withoutReason,
        originalAnimalIds: const [animal1, animal2],
      ),
      throwsA(isA<MedicalDocumentContractException>()),
    );
    expect(
      () => MedicalDocumentContractValidator.validateReview(
        request: otherWithoutComment,
        originalAnimalIds: const [animal1, animal2],
      ),
      throwsA(isA<MedicalDocumentContractException>()),
    );
    expect(
      () => MedicalDocumentContractValidator.validateReview(
        request: valid,
        originalAnimalIds: const [animal1, animal2],
      ),
      returnsNormally,
    );
  });

  test('creates a detached category draft without sharing mutable maps', () {
    final originalFields = <String, dynamic>{
      'name': 'Medicine',
      'schedule': <String, dynamic>{'frequency': 'daily'},
    };
    final originalAdditional = <String, dynamic>{
      'metadata': <String, dynamic>{
        'reviewed': false,
        'warnings': <String>['Do not persist'],
      },
    };
    final extraction = MedicalDocumentExtractionEntity(
      documentType: MedicalDocumentCategory.prescription,
      medications: [
        MedicalDocumentItemEntity(id: 'medication-1', fields: originalFields),
      ],
      additionalFields: originalAdditional,
      warnings: const ['Do not persist'],
    );

    final draft = extraction.sanitizedFor(MedicalDocumentCategory.prescription);
    (draft.medications.single.fields['schedule']
            as Map<String, dynamic>)['frequency'] =
        'weekly';
    (draft.additionalFields['metadata'] as Map<String, dynamic>)['reviewed'] =
        true;

    expect(
      (originalFields['schedule'] as Map<String, dynamic>)['frequency'],
      'daily',
    );
    expect(
      (originalAdditional['metadata'] as Map<String, dynamic>)['reviewed'],
      isFalse,
    );
    expect(draft.warnings, ['Do not persist']);
    expect(
      draft.additionalFields['metadata'],
      containsPair('warnings', ['Do not persist']),
    );
  });
}
