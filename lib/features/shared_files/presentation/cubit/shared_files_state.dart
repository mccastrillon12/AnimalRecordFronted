import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:equatable/equatable.dart';

sealed class SharedFilesState extends Equatable {
  const SharedFilesState();

  @override
  List<Object?> get props => [];
}

class SharedFilesInitial extends SharedFilesState {}

class SharedFilesReceived extends SharedFilesState {
  final List<SharedFileEntity> files;

  const SharedFilesReceived(this.files);

  @override
  List<Object?> get props => [files];
}

class SharedFilesError extends SharedFilesState {
  final String message;

  const SharedFilesError(this.message);

  @override
  List<Object?> get props => [message];
}
