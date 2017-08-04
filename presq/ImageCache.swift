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
  typealias NodeType = CacheNode<K, V>

  var lru: NodeType?
  var mru: NodeType?

  var values: [K: NodeType] = [:]

  fileprivate let resolve: (K) throws -> V

  var count: Int { return values.count }
  let maxSize: Int

  init(maxSize: Int, resolve: @escaping (K) throws -> V) {
    self.resolve = resolve
    self.maxSize = maxSize
  }

  func maybeRemoveLRU() {
    guard count >= maxSize else { return }

    if let oldLru = lru {
      values[oldLru.key] = nil

      // If there is an lru, then make it's prev the new lru
      lru = oldLru.prev
      lru?.next = nil
    }
  }

  func dumpChain() {
    var keys = [K]()
    keys.reserveCapacity(count)

    var node_ = mru
    while let node = node_ {
      keys.append(node.key)
      node_ = node.next
    }

    print("chain from mru: \(keys)")

    keys.removeAll(keepingCapacity: true)
    node_ = lru
    while let node = node_ {
      keys.append(node.key)
      node_ = node.prev
    }
    print("chain from lru: \(keys)")
    if keys.first as? String == "2" {
      print("WE ARE HERE")
    }
  }

  func addMru(_ node: NodeType) {
    if let oldMru = mru {
      oldMru.prev = node
      node.next = oldMru
      mru = node
    } else {
      // It's the first node
      mru = node
      lru = node
    }
  }

  func moveToMru(_ node: NodeType) {
    // Maybe there is nothing to do
    if node === mru { return }

    // We may have to update the lru value.
    if node === lru {
      lru = node.prev
    }

    // Then, finally, move the node in the list.
    let oldPrev = node.prev
    let oldNext = node.next
    oldPrev?.next = oldNext
    oldNext?.prev = oldPrev

    // Then fixup the mru value.
    node.next = mru
    node.prev = nil
    mru?.prev = node
    mru = node
  }

  func find(key: K) throws -> V {
    if let node = values[key] {
      // Found it
      moveToMru(node)

      return node.value
    } else {
      let val = try resolve(key)

      maybeRemoveLRU()

      let newNode = NodeType(k: key, v: val)
      values[key] = newNode

      addMru(newNode)

      return val
    }
  }
}
