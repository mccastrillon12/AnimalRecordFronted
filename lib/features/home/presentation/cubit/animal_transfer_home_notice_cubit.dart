import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransferHomeNoticeCubit extends Cubit<bool> {
  final AnimalTransferRepository repository;
  bool _loading = false;

  TransferHomeNoticeCubit(this.repository) : super(false);

  Future<void> refresh() async {
    if (_loading || isClosed) return;
    _loading = true;
    try {
      final page = await repository.listRequests(
        direction: 'INCOMING',
        status: 'PENDING',
      );
      if (!isClosed) emit(page.items.isNotEmpty);
    } catch (_) {
      // Keep the last confirmed value if this refresh cannot reach the server.
    } finally {
      _loading = false;
    }
  }
}
