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
        animalIds: const ['animal-1', 'animal-2'],
        requestedCategory: MedicalDocumentCategory.prescription,
      );

      expect(cubit.state.phase, MedicalDocumentFlowPhase.reviewing);
      expect(
        cubit.state.selectedFinalCategory,
        MedicalDocumentCategory.prescription,
      );
      expect(cubit.state.draftExtraction?.medications, hasLength(1));
      expect(cubit.state.draftExtraction?.vaccinations, isEmpty);
      expect(cubit.state.assignmentsByAnimalId['animal-1'], [
        'diagnosis-1',
        'medication-1',
      ]);
      expect(pending.value?.documentId, 'document-1');

      cubit.updateAssignment('animal-2', const []);
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
        animalIds: const ['animal-1', 'animal-2'],
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
        animalIds: const ['animal-1', 'animal-2'],
      );
      expect(cubit.state.phase, MedicalDocumentFlowPhase.reviewing);

      await cubit.reset();
      expect(cubit.state.phase, MedicalDocumentFlowPhase.selecting);
      expect(cubit.state.remoteDocument, isNull);
      expect(pending.value, isNull);

      await cubit.startAnalysis(
        file: file,
        animalIds: const ['animal-1', 'animal-2'],
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
      animalIds: const ['animal-1', 'animal-2'],
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
    animalIds: const ['animal-1', 'animal-2'],
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
