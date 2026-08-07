import 'dart:async';

import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:animal_record/features/shared_files/domain/repositories/shared_files_repository.dart';
import 'package:animal_record/features/shared_files/domain/usecases/get_initial_shared_files_usecase.dart';
import 'package:animal_record/features/shared_files/domain/usecases/observe_shared_files_usecase.dart';
import 'package:animal_record/features/shared_files/domain/usecases/pick_manual_shared_file_usecase.dart';
import 'package:animal_record/features/shared_files/domain/usecases/export_shared_file_analysis_pdf_usecase.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_cubit.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSharedFilesRepository extends Mock implements SharedFilesRepository {}

void main() {
  late MockSharedFilesRepository repository;
  late StreamController<List<SharedFileEntity>> incomingFiles;
  late SharedFilesCubit cubit;

  const image = SharedFileEntity(
    path: '/tmp/photo.jpg',
    name: 'photo.jpg',
    mimeType: 'image/jpeg',
    type: SharedFileType.image,
  );

  setUp(() {
    repository = MockSharedFilesRepository();
    incomingFiles = StreamController<List<SharedFileEntity>>.broadcast();
    when(
      () => repository.observeIncomingFiles(),
    ).thenAnswer((_) => incomingFiles.stream);
    when(() => repository.getInitialFiles()).thenAnswer((_) async => const []);
    cubit = SharedFilesCubit(
      getInitialSharedFilesUseCase: GetInitialSharedFilesUseCase(repository),
      observeSharedFilesUseCase: ObserveSharedFilesUseCase(repository),
      pickManualSharedFileUseCase: PickManualSharedFileUseCase(repository),
      exportSharedFileAnalysisPdfUseCase: ExportSharedFileAnalysisPdfUseCase(
        repository,
      ),
    );
  });

  tearDown(() async {
    await cubit.close();
    await incomingFiles.close();
  });

  test('publica los archivos que iniciaron la aplicación', () async {
    when(
      () => repository.getInitialFiles(),
    ).thenAnswer((_) async => const [image]);

    await cubit.initialize();

    expect(cubit.state, const SharedFilesReceived([image]));
    verify(() => repository.getInitialFiles()).called(1);
    verify(() => repository.observeIncomingFiles()).called(1);
  });

  test(
    'publica archivos compartidos mientras la aplicación está abierta',
    () async {
      await cubit.initialize();

      incomingFiles.add(const [image]);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, const SharedFilesReceived([image]));
      expect(cubit.pendingFiles, const [image]);
      expect(cubit.hasPendingFiles, isTrue);
    },
  );

  test('controla acceso y permite descartar la intención pendiente', () async {
    await cubit.initialize();
    incomingFiles.add(const [image]);
    await Future<void>.delayed(Duration.zero);

    cubit.grantAccess();
    expect(cubit.accessGranted, isTrue);

    cubit.revokeAccess();
    cubit.clear();

    expect(cubit.accessGranted, isFalse);
    expect(cubit.hasPendingFiles, isFalse);
    expect(cubit.state, isA<SharedFilesInitial>());
  });

  test('publica un error si falla la carga inicial', () async {
    when(() => repository.getInitialFiles()).thenThrow(Exception('falló'));

    await cubit.initialize();

    expect(cubit.state, isA<SharedFilesError>());
  });

  test('delega la exportación PDF con todos los datos analizados', () async {
    final analysis = SharedFileAnalysisEntity(
      documentType: 'Fórmula variable',
      documentNumber: 'DOC-1',
      date: DateTime(2026, 1, 25),
      originalFileName: 'formula.pdf',
      patient: const SharedFilePatientAnalysisEntity(
        name: 'Brownie',
        recordId: 'AR-C012',
        species: 'Canino',
        breed: 'Labrador',
        age: '10 años',
        weight: '15 kg',
      ),
      tutor: const SharedFileTutorAnalysisEntity(
        name: 'Barbara James',
        identification: 'C.C. 1152234567',
        phoneNumber: '(+57) 312 456 78 90',
      ),
    );
    when(() => repository.exportAnalysisPdf(analysis)).thenAnswer((_) async {});

    await cubit.exportAnalysisPdf(analysis);

    verify(() => repository.exportAnalysisPdf(analysis)).called(1);
  });
}
