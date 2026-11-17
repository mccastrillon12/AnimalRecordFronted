abstract class HistoricalFileSaveService {
  Future<bool> save(List<int> downloadedBytes, String suggestedName);
}
