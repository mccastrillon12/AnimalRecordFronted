import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/diary/domain/repositories/diary_repository.dart';
import 'package:animal_record/features/diary/data/datasources/diary_remote_datasource.dart';

class DiaryRepositoryImpl implements DiaryRepository {
  final DiaryRemoteDataSource remoteDataSource;

  DiaryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<DiaryEntryEntity>>> getDiaryEntries(
    String animalId,
  ) async {
    try {
      final entries = await remoteDataSource.getDiaryEntries(animalId);
      return Right(entries);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DiaryEntryEntity>> createDiaryEntry(
    String animalId,
    Map<String, dynamic> data,
  ) async {
    try {
      final entry = await remoteDataSource.createDiaryEntry(animalId, data);
      return Right(entry);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DiaryEntryEntity>> updateDiaryEntry(
    String animalId,
    String entryId,
    Map<String, dynamic> data,
  ) async {
    try {
      final entry = await remoteDataSource.updateDiaryEntry(
        animalId,
        entryId,
        data,
      );
      return Right(entry);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDiaryEntry(
    String animalId,
    String entryId,
  ) async {
    try {
      await remoteDataSource.deleteDiaryEntry(animalId, entryId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAttachmentUploadUrl(
    String animalId,
    String entryId,
    String mimeType,
    int fileSize,
  ) async {
    try {
      final data = await remoteDataSource.getAttachmentUploadUrl(
        animalId, entryId, mimeType, fileSize,
      );
      return Right(data);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DiaryEntryEntity>> confirmAttachment(
    String animalId,
    String entryId,
    Map<String, dynamic> data,
  ) async {
    try {
      final entry = await remoteDataSource.confirmAttachment(
        animalId, entryId, data,
      );
      return Right(entry);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAttachment(
    String animalId,
    String entryId,
    String attachmentId,
  ) async {
    try {
      await remoteDataSource.deleteAttachment(animalId, entryId, attachmentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
