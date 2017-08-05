import XCTest
@testable import presq

func simpleResolve(key: String) -> Int {
  return Int(key)!
}

func iter<K, V>(from: CacheNode<K, V>?,
                next: (CacheNode<K, V>) -> CacheNode<K, V>? = { $0.next },
                doing: (CacheNode<K, V>) -> Bool) -> Bool {
  var node_ = from
  while let node = node_ {
    if !doing(node) { return false }
    node_ = next(node)
  }
  return true
}

class ImageCacheTests: XCTestCase {

  func checkConsistent<K, V>(_ cache: ImageCache<K, V>) -> Bool {
    // Check that the mru list and the dict have exactly the same set of keys.
    var keySet = Set(cache.values.keys)

    if !iter(from: cache.mru) { node in
      if !keySet.contains(node.key) {
        print("\(node.key) missing from keyset")
        return false
      }
      keySet.remove(node.key)
      return true
    } { return false }

    if keySet.count > 0 {
      print("Keys still in key set: \(keySet)")
      return false
    }

    // Check that node->next->prev == node
    if !iter(from: cache.mru) { node in
      if let next = node.next {
        guard let prev = next.prev else {
          print("Prev for node \(next.key) should not be nil")
          return false
        }
        if node !== prev {
          print("Node for \(node.key) not equal to next.prev \(String(describing: next.prev))")
          return false
        }
      }
      return true
    } { return false }

    // LRU and MRU should be reverses.
    var keysFromMru = [K]()
    _ = iter(from: cache.mru, next: { $0.next }) {
      keysFromMru.append($0.key)
      return true
    }
    var keysFromLru = [K]()
    _ = iter(from: cache.lru, next: { $0.prev }) {
      keysFromLru.append($0.key)
      return true
    }
    if keysFromMru != keysFromLru.reversed() {
      print("Chains not equal: \(keysFromMru) != \(keysFromLru)")
      return false
    }

    return true
  }

  func checkContains<K, V>(_ cache: ImageCache<K, V>, _ keys: [K]) -> Bool {
    for key in keys where cache.values[key] == nil {
      print("Key, '\(key)', missing from cache")
      return false
    }
    return true
  }

  func findAndCheck<K, V>(_ cache: ImageCache<K, V>, _ key: K) throws -> V? {
    let val = try cache.find(key: key)
    if !checkConsistent(cache) { return nil }
    //    XCTAssert(checkConsistent(cache))
    return val
  }

  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  // TODO: add some special cases like node was already mru/lru, or node was second from end.

  func testBasic() {
    let cache = ImageCache(maxSize: 100, resolve: simpleResolve)

    XCTAssertEqual(0, cache.count)

    XCTAssertEqual(1, try findAndCheck(cache, "1"))
    XCTAssertEqual(1, cache.count)
    XCTAssertEqual(1, try findAndCheck(cache, "1"))
    XCTAssertEqual(1, cache.count)
    XCTAssertEqual(2, try findAndCheck(cache, "2"))
    XCTAssertEqual(2, cache.count)
    XCTAssertEqual(3, try findAndCheck(cache, "3"))
    XCTAssertEqual(3, cache.count)
    XCTAssertEqual(1, try findAndCheck(cache, "1"))
    XCTAssertEqual(3, cache.count)
  }

  func testEvict() {
    let cache = ImageCache(maxSize: 4, resolve: simpleResolve)

    XCTAssertEqual(0, cache.count)
    XCTAssertEqual(1, try findAndCheck(cache, "1"))
    XCTAssertEqual(1, cache.count)
    XCTAssertEqual(2, try findAndCheck(cache, "2"))
    XCTAssertEqual(2, cache.count)
    XCTAssertEqual(3, try findAndCheck(cache, "3"))
    XCTAssertEqual(3, cache.count)
    XCTAssertEqual(4, try findAndCheck(cache, "4"))
    XCTAssertEqual(4, cache.count)
    XCTAssertEqual(5, try findAndCheck(cache, "5"))
    XCTAssertEqual(4, cache.count)
  }

  func testEvictLru() {
    let cache = ImageCache(maxSize: 4, resolve: simpleResolve)

    XCTAssertEqual(1, try findAndCheck(cache, "1"))
    XCTAssertEqual(2, try findAndCheck(cache, "2"))
    XCTAssertEqual(3, try findAndCheck(cache, "3"))
    XCTAssertEqual(4, try findAndCheck(cache, "4"))
    XCTAssert(checkContains(cache, ["1", "2", "3", "4"]))
    XCTAssertEqual(5, try findAndCheck(cache, "5"))
    XCTAssertEqual(4, cache.count)
    XCTAssert(checkContains(cache, ["2", "3", "4", "5"]))

    XCTAssertEqual(2, try findAndCheck(cache, "2"))
    XCTAssertEqual(6, try findAndCheck(cache, "6"))
    XCTAssertEqual(4, cache.count)
    XCTAssert(checkContains(cache, ["2", "4", "5", "6"]))
  }
}
