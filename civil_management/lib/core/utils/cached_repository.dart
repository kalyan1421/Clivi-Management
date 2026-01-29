/// Generic in-memory cache with LRU eviction
class CachedRepository<T> {
  final Map<String, CacheEntry<T>> _cache = {};
  final Duration cacheDuration;
  final int maxSize;

  CachedRepository({
    this.cacheDuration = const Duration(minutes: 5),
    this.maxSize = 100,
  });

  Future<T> getOrFetch(
    String key,
    Future<T> Function() fetcher,
  ) async {
    final cached = _cache[key];
    if (cached != null && !cached.isExpired(cacheDuration)) {
      // Move to end (LRU refresh)
      _cache.remove(key);
      _cache[key] = cached;
      return cached.value;
    }

    final value = await fetcher();
    
    // Evict oldest entries if at capacity
    while (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }
    
    _cache[key] = CacheEntry(value, DateTime.now());
    return value;
  }

  void invalidate(String key) => _cache.remove(key);
  void invalidateAll() => _cache.clear();
}

class CacheEntry<T> {
  final T value;
  final DateTime timestamp;

  CacheEntry(this.value, this.timestamp);

  bool isExpired(Duration cacheDuration) =>
      DateTime.now().difference(timestamp) > cacheDuration;
}
