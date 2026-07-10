import 'dart:async';

import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:animal_record/features/shared_files/domain/repositories/shared_files_repository.dart';
import 'package:animal_record/features/shared_files/domain/usecases/get_initial_shared_files_usecase.dart';
import 'package:animal_record/features/shared_files/domain/usecases/observe_shared_files_usecase.dart';
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
    when(() => repository.observeIncomingFiles()).thenAnswer(
      (_) => incomingFiles.stream,
    );
    when(() => repository.getInitialFiles()).thenAnswer((_) async => const []);
    cubit = SharedFilesCubit(
      getInitialSharedFilesUseCase: GetInitialSharedFilesUseCase(repository),
      observeSharedFilesUseCase: ObserveSharedFilesUseCase(repository),
    );
  });

  tearDown(() async {
    await cubit.close();
    await incomingFiles.close();
  });

  test('publica los archivos que iniciaron la aplicación', () async {
    when(() => repository.getInitialFiles()).thenAnswer((_) async => const [image]);

    await cubit.initialize();

    expect(cubit.state, const SharedFilesReceived([image]));
    verify(() => repository.getInitialFiles()).called(1);
    verify(() => repository.observeIncomingFiles()).called(1);
  });

  test('publica archivos compartidos mientras la aplicación está abierta', () async {
    await cubit.initialize();

    incomingFiles.add(const [image]);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, const SharedFilesReceived([image]));
  });

  test('publica un error si falla la carga inicial', () async {
    when(() => repository.getInitialFiles()).thenThrow(Exception('falló'));

    await cubit.initialize();

    expect(cubit.state, isA<SharedFilesError>());
  });
}
