import Foundation

class CacheNode<K, V> where K: Hashable {
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
  var lru: CacheNode<K, V>?
  var mru: CacheNode<K, V>?

  var values: [K: CacheNode<K, V>] = [:]

  fileprivate let resolve: (K) throws -> V

  var count: Int { return values.count }
  let maxSize: Int

  init(maxSize: Int, resolve: @escaping (K) throws -> V) {
    self.resolve = resolve
    self.maxSize = maxSize
  }

  func find(key: K) throws -> V {
    if let node = values[key] {
      // Found it

      // TODO: deal with the lru list
      print("FOUND IT: \(key)")
      return node.value
    } else {
      let val = try resolve(key)
      print("INSERTING: \(key)")

      if count >= maxSize {
        if let oldLru = lru {
          values.removeValue(forKey: oldLru.key)

          let oldPrev = oldLru.prev
          lru = oldPrev
          if oldPrev != nil {
            oldPrev?.next = nil
          }
        } else {
          print("lru never got set somehow. Bummer")
        }
      }

      let newNode = CacheNode<K, V>(k: key, v: val)
      values[key] = newNode

      if let oldMru = mru {
        mru = newNode
        oldMru.prev = newNode
        newNode.next = oldMru
      } else {
        // It's the first node
        mru = newNode
        lru = newNode
      }

      return val
    }
  }
}
