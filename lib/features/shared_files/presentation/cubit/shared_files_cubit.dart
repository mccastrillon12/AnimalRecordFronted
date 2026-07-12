import 'dart:async';

import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:animal_record/features/shared_files/domain/usecases/get_initial_shared_files_usecase.dart';
import 'package:animal_record/features/shared_files/domain/usecases/observe_shared_files_usecase.dart';
import 'package:animal_record/features/shared_files/domain/usecases/pick_manual_shared_file_usecase.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SharedFilesCubit extends Cubit<SharedFilesState> {
  final GetInitialSharedFilesUseCase getInitialSharedFilesUseCase;
  final ObserveSharedFilesUseCase observeSharedFilesUseCase;
  final PickManualSharedFileUseCase pickManualSharedFileUseCase;

  StreamSubscription<List<SharedFileEntity>>? _subscription;
  bool _receivedLiveFilesDuringInitialization = false;
  List<SharedFileEntity> _pendingFiles = const [];
  bool _accessGranted = false;

  List<SharedFileEntity> get pendingFiles => List.unmodifiable(_pendingFiles);
  bool get hasPendingFiles => _pendingFiles.isNotEmpty;
  bool get accessGranted => _accessGranted;

  SharedFilesCubit({
    required this.getInitialSharedFilesUseCase,
    required this.observeSharedFilesUseCase,
    required this.pickManualSharedFileUseCase,
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
    if (files.isEmpty) return;
    _pendingFiles = files;
    emit(SharedFilesReceived(files));
  }

  void grantAccess() => _accessGranted = true;

  Future<SharedFileEntity?> pickManualFile() => pickManualSharedFileUseCase();

  void revokeAccess() => _accessGranted = false;

  void clear() {
    _pendingFiles = const [];
    emit(SharedFilesInitial());
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
