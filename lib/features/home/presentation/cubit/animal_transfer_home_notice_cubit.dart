import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransferHomeNoticeCubit extends Cubit<TransferRequest?> {
  final AnimalTransferRepository repository;
  bool _loading = false;

  TransferHomeNoticeCubit(this.repository) : super(null);

  Future<void> refresh() async {
    if (_loading || isClosed) return;
    _loading = true;
    try {
      final page = await repository.listRequests(
        direction: 'INCOMING',
        status: 'PENDING',
      );
      if (!isClosed) {
        emit(
          page.items
              .where((request) => request.status == 'PENDING')
              .firstOrNull,
        );
      }
    } catch (_) {
      // Keep the last confirmed value if this refresh cannot reach the server.
    } finally {
      _loading = false;
    }
  }
}
