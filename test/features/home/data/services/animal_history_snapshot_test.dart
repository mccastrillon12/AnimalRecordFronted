import 'package:animal_record/features/home/data/models/animal_data_model.dart';
import 'package:animal_record/features/home/data/services/animal_history_snapshot.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/entities/animal_ownership.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/presentation/utils/animal_picture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements AnimalTransferRepository {}

void main() {
  const history = AnimalOwnershipHistory(
    periodId: 'period-1',
    publicationHash: 'hash-1',
  );
  final card = AnimalDataModel.fromJson({
    'id': 'animal-1',
    'name': 'Luna',
    'species': 'EQUINE',
    'sex': 'FEMALE',
    'transferStatus': 'TRANSFERRED',
    'readOnly': true,
    'ownershipHistory': {'periodId': 'period-1', 'publicationHash': 'hash-1'},
  });
  test(
    'publicación completa alimenta ficha, diario, documentos y fotos de solo lectura',
    () async {
      final repository = _Repository();
      const animal = HistoricalEntry(
        entryId: 'animal-entry',
        kind: 'ANIMAL',
        data: {
          'id': 'animal-1',
          'name': 'Luna anterior',
          'species': 'EQUINE',
          'breed': 'Criollo',
          'sex': 'FEMALE',
          'weight': 340,
          'isActive': true,
        },
        media: [HistoricalFile('photo-file', 'profilePictureUrl')],
      );
      const medical = HistoricalEntry(
        entryId: 'doc-entry',
        kind: 'MEDICAL_DOCUMENT',
        data: {
          'id': 'document-1',
          'status': 'ACCEPTED',
          'finalCategory': 'PRESCRIPTION',
          'originalFileName': 'formula.pdf',
          'mimeType': 'application/pdf',
          'fileSize': 3,
          'animalIds': ['animal-1'],
          'canReplace': true,
          'version': 2,
        },
        media: [HistoricalFile('original-file', 'storageKey')],
      );
      const diary = HistoricalEntry(
        entryId: 'diary-entry',
        kind: 'DIARY_ENTRY',
        data: {
          'id': 'note-1',
          'animalId': 'animal-1',
          'title': 'Consulta anterior',
          'content': 'Información guardada',
          'attachments': [
            {
              'id': 'attachment-1',
              'fileName': 'foto.png',
              'fileType': 'image',
              'url': 'https://expired.example.com',
            },
          ],
        },
        media: [HistoricalFile('attachment-1', 'attachments.0.url')],
      );
      when(
        () => repository.getHistory('period-1', 'hash-1'),
      ).thenAnswer((_) async => const TransferPage([animal], 'cursor+a%2Fb='));
      when(
        () => repository.getHistory(
          'period-1',
          'hash-1',
          cursor: 'cursor+a%2Fb=',
        ),
      ).thenAnswer((_) async => const TransferPage([medical, diary], null));
      final snapshot = await AnimalHistorySnapshot.load(history, repository);
      final animalData = AnimalHistorySnapshot.animal(card, snapshot);
      expect(animalData.name, 'Luna Anterior');
      expect(animalData.weight, 340);
      expect(animalData.canWrite, isFalse);
      expect(animalData.isActive, isTrue);
      expect(snapshot.photo?.fileId, 'photo-file');
      final document = AnimalHistorySnapshot.documents(snapshot).single;
      expect(document.originalFileName, 'formula.pdf');
      expect(document.canReplace, isFalse);
      expect(document.historicalFile?.entryId, 'doc-entry');
      final note = AnimalHistorySnapshot.diary(snapshot).single;
      expect(note.content, 'Información guardada');
      expect(note.attachments.single.url, isEmpty);
      expect(note.attachments.single.historicalFile?.fileId, 'attachment-1');
      verify(() => repository.getHistory('period-1', 'hash-1')).called(1);
      verify(
        () => repository.getHistory(
          'period-1',
          'hash-1',
          cursor: 'cursor+a%2Fb=',
        ),
      ).called(1);
      verifyNoMoreInteractions(repository);
    },
  );

  test(
    'la devolución mantiene una ficha vigente con el mismo ID y los datos nuevos',
    () {
      final returned = AnimalDataModel.fromJson({
        'id': 'animal-1',
        'name': 'Luna nueva',
        'species': 'EQUINE',
        'sex': 'FEMALE',
        'weight': 360,
      });
      expect(uniqueAnimalCards([card, returned, returned]), [returned]);
      expect(returned.canWrite, isTrue);
      expect(returned.canTransfer, isTrue);
      expect(card.canWrite, isFalse);
      expect(card.isActive, isTrue);
    },
  );

  test('valida la URL sin modificar la firma y elige iconos por especie', () {
    const signed =
        'https://example.com/photo?X-Amz-Signature=a%2Bb%2Fc&token=x%3D';
    expect(validAnimalImageUrl(signed), signed);
    String key(String url) =>
        animalImageCacheKey(url, animalId: 'animal-1', ownerId: 'owner-1');
    expect(
      key('https://example.com/photo?X-Amz-Signature=old&X-Amz-Expires=60'),
      key('https://example.com/photo?X-Amz-Signature=new&X-Amz-Expires=300'),
    );
    expect(
      key('https://example.com/photo?v=1&Signature=a'),
      isNot(key('https://example.com/photo?v=2&Signature=b')),
    );
    expect(
      key('https://example.com/new-photo?Signature=b'),
      isNot(key('https://example.com/photo?Signature=a')),
    );
    for (final value in [
      null,
      '',
      ' ',
      'invalid',
      'https://',
      'file:///photo.jpg',
      'javascript:alert(1)',
    ]) {
      expect(validAnimalImageUrl(value), isNull);
    }
    for (final item in {
      'EQUINE': 'equino',
      'BOVINE': 'bovino',
      'FELINE': 'cat',
      'CANINE': 'dog',
    }.entries) {
      expect(
        animalPictureIcon(species: item.key),
        'assets/illustrations/${item.value}_icon.svg',
      );
    }
    expect(
      animalPictureIcon(code: 'AR-E018'),
      'assets/illustrations/equino_icon.svg',
    );
  });
}
