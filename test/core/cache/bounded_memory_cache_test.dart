import 'package:animal_record/core/cache/bounded_memory_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'el presupuesto de bytes y el orden LRU limitan los datos retenidos',
    () {
      final evicted = <String>[];
      final cache = BoundedMemoryCache<String, String>(
        maxEntries: 2,
        maxBytes: 5,
        sizeOf: (value) => value.length,
        onEvicted: (key, _) => evicted.add(key),
      );
      cache['a'] = 'aa';
      cache['b'] = 'bb';
      expect(cache['a'], 'aa');
      cache['c'] = 'ccc';
      expect(cache['b'], isNull);
      expect(cache['a'], 'aa');
      expect(cache['c'], 'ccc');
      expect(cache.retainedBytes, 5);
      expect(evicted, ['b']);
      cache['oversize'] = '123456';
      expect(cache['oversize'], isNull);
      expect(cache.length, 2);
      cache.clear();
      expect(cache.retainedBytes, 0);
    },
  );

  test('reemplazar y eliminar contabiliza los bytes una sola vez', () {
    final cache = BoundedMemoryCache<int, String>(
      maxEntries: 2,
      maxBytes: 10,
      sizeOf: (value) => value.length,
    );
    cache[1] = '1234';
    cache[1] = '1';
    cache[2] = '12';
    cache[3] = '123';
    expect(cache[1], isNull);
    expect(cache.retainedBytes, 5);
    cache.remove(2);
    expect(cache.retainedBytes, 3);
  });
}
