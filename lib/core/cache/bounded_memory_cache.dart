/// LRU cache bounded by both entry count and estimated retained bytes.
class BoundedMemoryCache<K, V> {
  final int maxEntries;
  final int maxBytes;
  final int Function(V) sizeOf;
  final void Function(K, V)? onEvicted;
  final _values = <K, (V, int)>{};
  int _bytes = 0;

  BoundedMemoryCache({
    required this.maxEntries,
    required this.maxBytes,
    required this.sizeOf,
    this.onEvicted,
  }) : assert(maxEntries > 0),
       assert(maxBytes > 0);

  int get length => _values.length;
  int get retainedBytes => _bytes;
  Iterable<K> get keys => _values.keys;

  V? operator [](K key) {
    final entry = _values.remove(key);
    if (entry == null) return null;
    _values[key] = entry;
    return entry.$1;
  }

  void operator []=(K key, V value) {
    remove(key);
    final bytes = sizeOf(value);
    if (bytes > maxBytes) return;
    _values[key] = (value, bytes);
    _bytes += bytes;
    while (_values.length > maxEntries || _bytes > maxBytes) {
      final oldest = _values.keys.first;
      final removed = remove(oldest);
      if (removed != null) onEvicted?.call(oldest, removed);
    }
  }

  V? remove(K key) {
    final entry = _values.remove(key);
    if (entry == null) return null;
    _bytes -= entry.$2;
    return entry.$1;
  }

  void clear() {
    _values.clear();
    _bytes = 0;
  }
}
