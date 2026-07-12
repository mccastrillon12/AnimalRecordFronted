import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:animal_record/features/shared_files/domain/repositories/shared_files_repository.dart';
import 'package:animal_record/features/shared_files/domain/usecases/pick_manual_shared_file_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSharedFilesRepository extends Mock implements SharedFilesRepository {}

void main() {
  late MockSharedFilesRepository repository;
  late PickManualSharedFileUseCase useCase;

  setUp(() {
    repository = MockSharedFilesRepository();
    useCase = PickManualSharedFileUseCase(repository);
  });

  test('acepta una imagen dentro del límite', () async {
    const image = SharedFileEntity(
      path: '/tmp/photo.jpg',
      name: 'photo.jpg',
      mimeType: 'image/jpeg',
      type: SharedFileType.image,
      size: PickManualSharedFileUseCase.maximumImageSize,
    );
    when(() => repository.pickManualFile()).thenAnswer((_) async => image);

    expect(await useCase(), image);
  });

  test('rechaza una imagen mayor a 1 MB', () async {
    const image = SharedFileEntity(
      path: '/tmp/photo.jpg',
      name: 'photo.jpg',
      mimeType: 'image/jpeg',
      type: SharedFileType.image,
      size: PickManualSharedFileUseCase.maximumImageSize + 1,
    );
    when(() => repository.pickManualFile()).thenAnswer((_) async => image);

    expect(useCase(), throwsA(isA<ManualFileSelectionException>()));
  });

  test('rechaza un PDF mayor a 5 MB', () async {
    const pdf = SharedFileEntity(
      path: '/tmp/file.pdf',
      name: 'file.pdf',
      mimeType: 'application/pdf',
      type: SharedFileType.pdf,
      size: PickManualSharedFileUseCase.maximumPdfSize + 1,
    );
    when(() => repository.pickManualFile()).thenAnswer((_) async => pdf);

    expect(useCase(), throwsA(isA<ManualFileSelectionException>()));
  });

  test('conserva la cancelación del selector', () async {
    when(() => repository.pickManualFile()).thenAnswer((_) async => null);

    expect(await useCase(), isNull);
  });
}
