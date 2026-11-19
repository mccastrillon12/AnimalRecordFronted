import '../entities/animal_transfer_data.dart';
import '../entities/incoming_transfer_snapshot.dart';
export '../entities/incoming_transfer_snapshot.dart';

abstract interface class IncomingTransferPreviewRepository {
  TransferPage<TransferRequest>? get pendingRequests;
  void useAccount(String accountId);
  void clear();
  IncomingTransferSnapshot? peek(String id);
  void invalidateDetail(String id);
  void removeRequest(String id);
  Future<TransferPage<TransferRequest>> refreshPending();
  Future<IncomingTransferSnapshot> loadDetail(String id);
  Future<void> prefetchPending();
  void updatePage(String id, TransferDetail detail);
}
