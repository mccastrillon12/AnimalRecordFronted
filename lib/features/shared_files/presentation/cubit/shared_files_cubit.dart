import 'dart:async';

import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:animal_record/features/shared_files/domain/usecases/get_initial_shared_files_usecase.dart';
import 'package:animal_record/features/shared_files/domain/usecases/observe_shared_files_usecase.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SharedFilesCubit extends Cubit<SharedFilesState> {
  final GetInitialSharedFilesUseCase getInitialSharedFilesUseCase;
  final ObserveSharedFilesUseCase observeSharedFilesUseCase;

  StreamSubscription<List<SharedFileEntity>>? _subscription;
  bool _receivedLiveFilesDuringInitialization = false;

  SharedFilesCubit({
    required this.getInitialSharedFilesUseCase,
    required this.observeSharedFilesUseCase,
  }) : super(SharedFilesInitial());

  Future<void> initialize() async {
    await _subscription?.cancel();
    _receivedLiveFilesDuringInitialization = false;
    _subscription = observeSharedFilesUseCase().listen(
      (files) {
        _receivedLiveFilesDuringInitialization = true;
        _emitFiles(files);
      },
      onError: (Object error, StackTrace stackTrace) {
        emit(SharedFilesError(error.toString()));
      },
    );

    try {
      final initialFiles = await getInitialSharedFilesUseCase();
      if (!_receivedLiveFilesDuringInitialization) {
        _emitFiles(initialFiles);
      }
    } catch (error) {
      emit(SharedFilesError(error.toString()));
    }
  }

  void _emitFiles(List<SharedFileEntity> files) {
    if (files.isNotEmpty) emit(SharedFilesReceived(files));
  }

  void clear() => emit(SharedFilesInitial());

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
