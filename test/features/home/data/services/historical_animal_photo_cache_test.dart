import 'package:animal_record/features/home/domain/usecases/load_animal_photo_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/get_animal_by_id_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/animal_history_usecases.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_picture.dart';
import 'package:flutter/material.dart';
import 'package:animal_record/features/home/data/services/historical_animal_photo_cache.dart';
import 'package:animal_record/features/home/domain/entities/animal_ownership.dart';
import 'package:flutter_test/flutter_test.dart';

class _GetAnimal extends Mock implements GetAnimalByIdUseCase {}

class _Download extends Mock implements DownloadHistoricalFileUseCase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late HistoricalAnimalPhotoCache cache;
  var account = 'owner-1';
  final image = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );
  const photo = HistoricalFileReference(
    periodId: 'period-1',
    publicationHash: 'hash-1',
    entryId: 'entry-1',
    fileId: 'photo-1',
  );
  HistoricalAnimalPhotoCache createCache() => HistoricalAnimalPhotoCache(
    readAccountId: () async => account,
    cacheDirectory: () async => directory,
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'animal-photo-cache-test-',
    );
    account = 'owner-1';
    cache = createCache();
  });
  tearDown(() => directory.delete(recursive: true));

  test(
    'los presupuestos de memoria y disco no impiden devolver una foto válida',
    () async {
      cache = HistoricalAnimalPhotoCache(
        readAccountId: () async => account,
        cacheDirectory: () async => directory,
        maxMemoryBytes: 1,
        maxDiskBytes: 1,
      );
      var downloads = 0;
      Future<List<int>> download() async {
        downloads++;
        return image;
      }

      expect(await cache.load(photo, download), image);
      expect(cache.peek(photo), isNull);
      expect(await cache.load(photo, download), image);
      expect(downloads, 2);
      final stored = await Directory(
        '${directory.path}/historical_animal_photos_v1',
      ).list().toList();
      expect(stored, isEmpty);
    },
  );

  testWidgets(
    'la foto preparada desde la lista aparece en el primer frame de la ficha',
    (tester) async {
      var downloads = 0;
      final bytes = await tester.runAsync(
        () => cache.load(photo, () async {
          downloads++;
          return image;
        }),
      );
      di.sl.registerSingleton(
        LoadAnimalPhotoUseCase(
          photos: cache,
          downloadFile: _Download(),
          getAnimal: _GetAnimal(),
        ),
      );
      addTearDown(() => di.sl.unregister<LoadAnimalPhotoUseCase>());
      const animal = AnimalModel(
        id: 'animal-1',
        name: 'Luna',
        code: 'AR-E018',
        family: 'Equino',
        transferStatus: 'TRANSFERRED',
        readOnly: true,
        ownershipHistory: AnimalOwnershipHistory(
          periodId: 'period-1',
          publicationHash: 'hash-1',
          photo: photo,
        ),
      );
      Widget picture(double size) => MaterialApp(
        home: AnimalPicture(
          animal: animal,
          width: size,
          height: size,
          iconSize: 16,
        ),
      );
      await tester.pumpWidget(picture(32));
      expect(
        identical(
          (tester.widget<Image>(find.byType(Image)).image as MemoryImage).bytes,
          bytes,
        ),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(picture(180));
      expect(
        identical(
          (tester.widget<Image>(find.byType(Image)).image as MemoryImage).bytes,
          bytes,
        ),
        isTrue,
      );
      expect(downloads, 1);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'lista y ficha comparten una descarga y la foto persiste al reabrir la app',
    () async {
      var downloads = 0;
      final pending = Completer<List<int>>();
      Future<List<int>> download() {
        downloads++;
        return pending.future;
      }

      final first = cache.load(photo, download);
      final simultaneous = cache.load(photo, download);
      pending.complete(image);
      expect(await first, image);
      expect(await simultaneous, image);
      expect(await cache.load(photo, download), image);
      expect(downloads, 1);
      cache = createCache();
      expect(await cache.load(photo, download), image);
      expect(downloads, 1);
    },
  );

  test('cuenta y publicación distintas no comparten sus fotos', () async {
    var downloads = 0;
    Future<List<int>> download() async {
      downloads++;
      return image;
    }

    await cache.load(photo, download);
    account = 'owner-2';
    await cache.load(photo, download);
    await cache.load(
      const HistoricalFileReference(
        periodId: 'period-1',
        publicationHash: 'hash-2',
        entryId: 'entry-1',
        fileId: 'photo-1',
      ),
      download,
    );
    expect(downloads, 3);
    account = 'owner-1';
    cache.clearMemory();
    await cache.load(photo, download);
    expect(downloads, 3);
  });

  test(
    'una foto corrupta no queda guardada y puede descargarse de nuevo',
    () async {
      await expectLater(
        cache.load(photo, () async => [1, 2, 3]),
        throwsA(anything),
      );
      expect(await cache.load(photo, () async => image), image);
      cache = createCache();
      expect(
        await cache.load(
          photo,
          () async => throw StateError('No debe consultar el backend'),
        ),
        image,
      );
    },
  );

  test('una caché corrupta se reemplaza por una foto válida', () async {
    await cache.load(photo, () async => image);
    final stored = (await Directory(
      '${directory.path}/historical_animal_photos_v1',
    ).list().toList()).whereType<File>().single;
    await stored.writeAsBytes([1, 2, 3]);
    cache = createCache();
    var downloads = 0;
    expect(
      await cache.load(photo, () async {
        downloads++;
        return image;
      }),
      image,
    );
    expect(downloads, 1);
    cache = createCache();
    expect(
      await cache.load(photo, () async => throw StateError('Ya está guardada')),
      image,
    );
  });

  test(
    'el cierre de sesión descarta descargas pendientes de la sesión anterior',
    () async {
      final pending = Completer<List<int>>();
      final started = Completer<void>();
      final loading = cache.load(photo, () {
        started.complete();
        return pending.future;
      });
      final expectation = expectLater(loading, throwsStateError);
      await started.future;
      cache.clearMemory();
      pending.complete(image);
      await expectation;
      expect(await cache.load(photo, () async => image), image);
    },
  );

  test(
    'un fallo de almacenamiento no impide mostrar ni reutilizar la foto en memoria',
    () async {
      cache = HistoricalAnimalPhotoCache(
        readAccountId: () async => account,
        cacheDirectory: () async =>
            throw const FileSystemException('Sin espacio'),
      );
      var downloads = 0;
      Future<List<int>> download() async {
        downloads++;
        return image;
      }

      expect(await cache.load(photo, download), image);
      expect(await cache.load(photo, download), image);
      expect(downloads, 1);
    },
  );
}
