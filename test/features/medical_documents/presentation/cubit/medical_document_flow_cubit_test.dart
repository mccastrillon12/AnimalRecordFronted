import 'package:animal_record/core/network/api_exception.dart';
import 'package:animal_record/features/medical_documents/data/datasources/pending_medical_document_local_datasource.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:animal_record/features/medical_documents/domain/repositories/medical_documents_repository.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/medical_document_flow_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/medical_document_flow_state.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:flutter_test/flutter_test.dart';

const animal1Id = '11111111-1111-4111-8111-111111111111';
const animal2Id = '22222222-2222-4222-8222-222222222222';

void main() {
  const file = SharedFileEntity(
    path: '/tmp/formula.pdf',
    name: 'formula.pdf',
    mimeType: 'application/pdf',
    type: SharedFileType.pdf,
    size: 2048,
  );

  test(
    'polls, keeps one final category and accepts different assignments',
    () async {
      final repository = _FakeMedicalDocumentsRepository(
        analyzeResponse: _document(MedicalDocumentStatus.analyzing),
        getResponses: [_document(MedicalDocumentStatus.reviewPending)],
        reviewResponse: _document(MedicalDocumentStatus.accepted, version: 2),
      );
      final pending = _MemoryPendingDataSource();
      final cubit = _buildCubit(repository, pending);
      addTearDown(cubit.close);

      await cubit.startAnalysis(
        file: file,
        animalIds: const [animal1Id, animal2Id],
        requestedCategory: MedicalDocumentCategory.prescription,
      );

      expect(cubit.state.phase, MedicalDocumentFlowPhase.reviewing);
      expect(
        cubit.state.selectedFinalCategory,
        MedicalDocumentCategory.prescription,
      );
      expect(cubit.state.draftExtraction?.medications, hasLength(1));
      expect(cubit.state.draftExtraction?.vaccinations, isEmpty);
      expect(cubit.state.assignmentsByAnimalId[animal1Id], [
        'diagnosis-1',
        'medication-1',
      ]);
      expect(pending.value?.documentId, 'document-1');

      cubit.updateAssignment(animal2Id, const []);
      await cubit.accept();

      expect(cubit.state.phase, MedicalDocumentFlowPhase.completed);
      final request = repository.lastReviewRequest!;
      expect(request.finalCategory, MedicalDocumentCategory.prescription);
      expect(request.validatedExtraction?.vaccinations, isEmpty);
      expect(request.assignments, hasLength(2));
      expect(request.assignments.first.extractedItemIds, [
        'diagnosis-1',
        'medication-1',
      ]);
      expect(request.assignments.last.extractedItemIds, isEmpty);
      expect(pending.value, isNull);
    },
  );

  test(
    'refreshes the latest version after a 409 without losing the draft',
    () async {
      final repository = _FakeMedicalDocumentsRepository(
        analyzeResponse: _document(MedicalDocumentStatus.analyzing),
        getResponses: [
          _document(MedicalDocumentStatus.reviewPending),
          _document(MedicalDocumentStatus.reviewPending, version: 7),
        ],
        reviewError: const ApiException(
          statusCode: 409,
          message: 'Version conflict',
        ),
      );
      final cubit = _buildCubit(repository, _MemoryPendingDataSource());
      addTearDown(cubit.close);

      await cubit.startAnalysis(
        file: file,
        animalIds: const [animal1Id, animal2Id],
        requestedCategory: MedicalDocumentCategory.prescription,
      );
      final draftBeforeConflict = cubit.state.draftExtraction;
      await cubit.accept();

      expect(cubit.state.phase, MedicalDocumentFlowPhase.reviewing);
      expect(cubit.state.remoteDocument?.version, 7);
      expect(cubit.state.versionConflict, isTrue);
      expect(cubit.state.draftExtraction, same(draftBeforeConflict));
      expect(cubit.state.message, contains('confirma nuevamente'));
    },
  );

  test(
    'reset discards the previous result and allows a fresh analysis',
    () async {
      final repository = _FakeMedicalDocumentsRepository(
        analyzeResponse: _document(MedicalDocumentStatus.analyzing),
        getResponses: [
          _document(MedicalDocumentStatus.reviewPending),
          _document(MedicalDocumentStatus.reviewPending),
        ],
      );
      final pending = _MemoryPendingDataSource();
      final cubit = _buildCubit(repository, pending);
      addTearDown(cubit.close);

      await cubit.startAnalysis(
        file: file,
        animalIds: const [animal1Id, animal2Id],
      );
      expect(cubit.state.phase, MedicalDocumentFlowPhase.reviewing);

      await cubit.reset();
      expect(cubit.state.phase, MedicalDocumentFlowPhase.selecting);
      expect(cubit.state.remoteDocument, isNull);
      expect(pending.value, isNull);

      await cubit.startAnalysis(
        file: file,
        animalIds: const [animal1Id, animal2Id],
      );
      expect(cubit.state.phase, MedicalDocumentFlowPhase.reviewing);
      expect(repository.analyzeCalls, 2);
    },
  );

  test('rejects and clears a review cancelled by the user', () async {
    final repository = _FakeMedicalDocumentsRepository(
      analyzeResponse: _document(MedicalDocumentStatus.analyzing),
      getResponses: [_document(MedicalDocumentStatus.reviewPending)],
      reviewResponse: _document(MedicalDocumentStatus.rejected, version: 2),
    );
    final pending = _MemoryPendingDataSource();
    final cubit = _buildCubit(repository, pending);
    addTearDown(cubit.close);

    await cubit.startAnalysis(
      file: file,
      animalIds: const [animal1Id, animal2Id],
    );
    expect(cubit.state.phase, MedicalDocumentFlowPhase.reviewing);

    final discarded = await cubit.discardCurrentFlow();

    expect(discarded, isTrue);
    expect(
      repository.lastReviewRequest?.decision,
      MedicalDocumentReviewDecision.reject,
    );
    expect(cubit.state.phase, MedicalDocumentFlowPhase.selecting);
    expect(cubit.state.remoteDocument, isNull);
    expect(pending.value, isNull);
  });

  test(
    'keeps the pending id after a polling error and resumes with GET',
    () async {
      final repository = _FakeMedicalDocumentsRepository(
        analyzeResponse: _document(MedicalDocumentStatus.analyzing),
        getResponses: const [],
      );
      final pending = _MemoryPendingDataSource();
      final cubit = _buildCubit(repository, pending);
      addTearDown(cubit.close);

      await cubit.startAnalysis(
        file: file,
        animalIds: const [animal1Id, animal2Id],
      );

      expect(cubit.state.phase, MedicalDocumentFlowPhase.pollingPaused);
      expect(pending.value?.documentId, 'document-1');

      repository.getResponses.add(
        _document(MedicalDocumentStatus.reviewPending),
      );
      await cubit.resumePolling();

      expect(cubit.state.phase, MedicalDocumentFlowPhase.reviewing);
      expect(repository.analyzeCalls, 1);
    },
  );

  test('restores a persisted flow with GET without uploading again', () async {
    final repository = _FakeMedicalDocumentsRepository(
      analyzeResponse: _document(MedicalDocumentStatus.analyzing),
      getResponses: [_document(MedicalDocumentStatus.reviewPending)],
    );
    final pending = _MemoryPendingDataSource()
      ..value = PendingMedicalDocumentFlow(
        documentId: 'document-1',
        animalIds: const [animal1Id, animal2Id],
        startedAt: DateTime.utc(2026, 8, 8),
        requestedCategory: MedicalDocumentCategory.prescription,
      );
    final cubit = _buildCubit(repository, pending);
    addTearDown(cubit.close);

    final restored = await cubit.resumePending();

    expect(restored, isTrue);
    expect(cubit.state.phase, MedicalDocumentFlowPhase.reviewing);
    expect(cubit.state.animalIds, const [animal1Id, animal2Id]);
    expect(repository.analyzeCalls, 0);
  });

  test('keeps a failed flow until the user explicitly resets it', () async {
    final repository = _FakeMedicalDocumentsRepository(
      analyzeResponse: _document(MedicalDocumentStatus.analyzing),
      getResponses: [_document(MedicalDocumentStatus.failed)],
    );
    final pending = _MemoryPendingDataSource();
    final cubit = _buildCubit(repository, pending);
    addTearDown(cubit.close);

    await cubit.startAnalysis(
      file: file,
      animalIds: const [animal1Id, animal2Id],
    );

    expect(cubit.state.phase, MedicalDocumentFlowPhase.failed);
    expect(pending.value?.documentId, 'document-1');

    await cubit.reset();
    expect(pending.value, isNull);
  });

  test(
    'does not mutate detection when an unclassified flow selects a final category',
    () async {
      final repository = _FakeMedicalDocumentsRepository(
        analyzeResponse: _document(MedicalDocumentStatus.analyzing),
        getResponses: [_unclassifiedDocument()],
      );
      final cubit = _buildCubit(repository, _MemoryPendingDataSource());
      addTearDown(cubit.close);

      await cubit.startAnalysis(
        file: file,
        animalIds: const [animal1Id, animal2Id],
        requestedCategory: MedicalDocumentCategory.prescription,
      );

      expect(cubit.state.remoteDocument?.detectedCategories, isEmpty);
      expect(cubit.state.remoteDocument?.primaryDetectedCategory, isNull);
      expect(
        cubit.state.remoteDocument?.classificationOutcome,
        MedicalDocumentClassificationOutcome.unclassified,
      );
      expect(
        cubit.state.selectedFinalCategory,
        MedicalDocumentCategory.prescription,
      );
      expect(
        cubit.state.draftExtraction?.documentType,
        MedicalDocumentCategory.prescription,
      );
    },
  );

  test('refreshes the latest version when rejection conflicts', () async {
    final repository = _FakeMedicalDocumentsRepository(
      analyzeResponse: _document(MedicalDocumentStatus.analyzing),
      getResponses: [
        _document(MedicalDocumentStatus.reviewPending),
        _document(MedicalDocumentStatus.reviewPending, version: 5),
      ],
      reviewError: const ApiException(
        statusCode: 409,
        message: 'Version conflict',
      ),
    );
    final pending = _MemoryPendingDataSource();
    final cubit = _buildCubit(repository, pending);
    addTearDown(cubit.close);

    await cubit.startAnalysis(
      file: file,
      animalIds: const [animal1Id, animal2Id],
    );
    await cubit.reject();

    expect(cubit.state.phase, MedicalDocumentFlowPhase.reviewing);
    expect(cubit.state.remoteDocument?.version, 5);
    expect(cubit.state.versionConflict, isTrue);
    expect(pending.value?.documentId, 'document-1');
  });

  test(
    'keeps multiple category extractions separate when accepting one',
    () async {
      final repository = _FakeMedicalDocumentsRepository(
        analyzeResponse: _document(MedicalDocumentStatus.analyzing),
        getResponses: [_multipleDocument()],
        reviewResponse: _document(MedicalDocumentStatus.accepted, version: 2),
      );
      final cubit = _buildCubit(repository, _MemoryPendingDataSource());
      addTearDown(cubit.close);

      await cubit.startAnalysis(
        file: file,
        animalIds: const [animal1Id, animal2Id],
      );
      expect(cubit.state.remoteDocument?.detectedCategories, hasLength(2));

      cubit.selectFinalCategory(MedicalDocumentCategory.vaccinationCard);
      await cubit.accept();

      final extraction = repository.lastReviewRequest?.validatedExtraction;
      expect(
        repository.lastReviewRequest?.finalCategory,
        MedicalDocumentCategory.vaccinationCard,
      );
      expect(extraction?.vaccinations, hasLength(1));
      expect(extraction?.medications, isEmpty);
      expect(extraction?.clinicalHistory, isNull);
    },
  );
}

MedicalDocumentFlowCubit _buildCubit(
  _FakeMedicalDocumentsRepository repository,
  _MemoryPendingDataSource pending,
) {
  return MedicalDocumentFlowCubit(
    analyzeUseCase: AnalyzeMedicalDocumentUseCase(repository),
    getDocumentUseCase: GetMedicalDocumentUseCase(repository),
    reviewUseCase: ReviewMedicalDocumentUseCase(repository),
    pendingLocalDataSource: pending,
    pollDelay: (_) async {},
  );
}

MedicalDocumentEntity _document(
  MedicalDocumentStatus status, {
  int version = 1,
}) {
  const extraction = MedicalDocumentExtractionEntity(
    documentType: MedicalDocumentCategory.prescription,
    summary: 'Fórmula veterinaria',
    diagnoses: [
      MedicalDocumentItemEntity(
        id: 'diagnosis-1',
        fields: {'name': 'Pancreatitis'},
      ),
    ],
    medications: [
      MedicalDocumentItemEntity(
        id: 'medication-1',
        fields: {'name': 'ProtectionPets', 'route': 'oral'},
      ),
    ],
    vaccinations: [
      MedicalDocumentItemEntity(id: 'vaccination-1', fields: {'name': 'Rabia'}),
    ],
  );
  return MedicalDocumentEntity(
    id: 'document-1',
    animalIds: const [animal1Id, animal2Id],
    originalFileName: 'formula.pdf',
    mimeType: 'application/pdf',
    fileSize: 2048,
    status: status,
    requestedCategory: MedicalDocumentCategory.prescription,
    primaryDetectedCategory: MedicalDocumentCategory.prescription,
    classificationOutcome: MedicalDocumentClassificationOutcome.match,
    extractionsByCategory: const {
      MedicalDocumentCategory.prescription: extraction,
    },
    finalCategory: status == MedicalDocumentStatus.accepted
        ? MedicalDocumentCategory.prescription
        : null,
    validatedExtraction: status == MedicalDocumentStatus.accepted
        ? extraction
        : null,
    version: version,
  );
}

MedicalDocumentEntity _unclassifiedDocument() {
  return const MedicalDocumentEntity(
    id: 'document-1',
    animalIds: [animal1Id, animal2Id],
    originalFileName: 'menu.pdf',
    mimeType: 'application/pdf',
    fileSize: 2048,
    status: MedicalDocumentStatus.reviewPending,
    requestedCategory: MedicalDocumentCategory.prescription,
    classificationOutcome: MedicalDocumentClassificationOutcome.unclassified,
    extractionsByCategory: {
      MedicalDocumentCategory.other: MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.other,
        summary: 'Contenido no clasificado',
      ),
    },
    version: 1,
  );
}

MedicalDocumentEntity _multipleDocument() {
  return const MedicalDocumentEntity(
    id: 'document-1',
    animalIds: [animal1Id, animal2Id],
    originalFileName: 'historia-vacunas.pdf',
    mimeType: 'application/pdf',
    fileSize: 2048,
    status: MedicalDocumentStatus.reviewPending,
    primaryDetectedCategory: MedicalDocumentCategory.clinicalHistory,
    detectedCategories: [
      DetectedMedicalDocumentCategoryEntity(
        category: MedicalDocumentCategory.clinicalHistory,
      ),
      DetectedMedicalDocumentCategoryEntity(
        category: MedicalDocumentCategory.vaccinationCard,
      ),
    ],
    classificationOutcome: MedicalDocumentClassificationOutcome.multiple,
    extractionsByCategory: {
      MedicalDocumentCategory.clinicalHistory: MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.clinicalHistory,
        clinicalHistory: {'reasonForConsultation': 'Control'},
      ),
      MedicalDocumentCategory.vaccinationCard: MedicalDocumentExtractionEntity(
        documentType: MedicalDocumentCategory.vaccinationCard,
        vaccinations: [
          MedicalDocumentItemEntity(
            id: 'vaccination-1',
            fields: {'name': 'Rabies'},
          ),
        ],
      ),
    },
    version: 1,
  );
}

class _FakeMedicalDocumentsRepository implements MedicalDocumentsRepository {
  final MedicalDocumentEntity analyzeResponse;
  final List<MedicalDocumentEntity> getResponses;
  final MedicalDocumentEntity? reviewResponse;
  final Object? reviewError;
  ReviewMedicalDocumentRequest? lastReviewRequest;
  int analyzeCalls = 0;

  _FakeMedicalDocumentsRepository({
    required this.analyzeResponse,
    required List<MedicalDocumentEntity> getResponses,
    this.reviewResponse,
    this.reviewError,
  }) : getResponses = [...getResponses];

  @override
  Future<MedicalDocumentEntity> analyze(
    AnalyzeMedicalDocumentRequest request,
  ) async {
    analyzeCalls++;
    return analyzeResponse;
  }

  @override
  Future<MedicalDocumentEntity> getById(String documentId) async {
    if (getResponses.isEmpty) throw StateError('No GET response configured');
    return getResponses.removeAt(0);
  }

  @override
  Future<MedicalDocumentEntity> review(
    String documentId,
    ReviewMedicalDocumentRequest request,
  ) async {
    lastReviewRequest = request;
    if (reviewError != null) throw reviewError!;
    return reviewResponse!;
  }

  @override
  Future<List<MedicalDocumentEntity>> getByAnimal(
    String animalId, {
    MedicalDocumentCategory? category,
  }) async => const [];

  @override
  Future<Uri> getDownloadUri(String documentId) async =>
      Uri.parse('https://example.test/original');
}

class _MemoryPendingDataSource
    implements PendingMedicalDocumentLocalDataSource {
  PendingMedicalDocumentFlow? value;

  @override
  Future<void> save(PendingMedicalDocumentFlow flow) async => value = flow;

  @override
  PendingMedicalDocumentFlow? read() => value;

  @override
  Future<void> clear() async => value = null;
}
