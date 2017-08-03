import Foundation

private class CacheNode<K, V> where K: Hashable {
  let key: K
  let value: V
  var prev: CacheNode<K, V>?
  var next: CacheNode<K, V>?

  init(k: K, v: V) {
    key = k
    value = v
  }
}

// An LRU cache
class ImageCache<K, V> where K: Hashable {
  fileprivate var lru: CacheNode<K, V>?
  fileprivate var mru: CacheNode<K, V>?

  fileprivate var values: [K: V] = [:]

  fileprivate let resolve: (K) throws -> V

  init(resolve: @escaping (K) throws -> V) {
    self.resolve = resolve
  }

  func find(key: K) throws -> V {
    if let val = values[key] {
      // Found it

      // TODO: deal with the lru list
      print("FOUND IT: \(key)")
      return val
    } else {
      let val = try resolve(key)
      print("INSERTING: \(key)")
      values[key] = val
      return val
    }
  }
}
