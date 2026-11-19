import 'animal_transfer_data.dart';

class IncomingTransferSnapshot {
  final TransferRequest request;
  final List<TransferItem> items;
  final Map<String, String?> itemCursors;
  IncomingTransferSnapshot(
    this.request,
    Iterable<TransferItem> items,
    Map<String, String?> cursors,
  ) : items = List.unmodifiable(items),
      itemCursors = Map.unmodifiable(cursors);
}
