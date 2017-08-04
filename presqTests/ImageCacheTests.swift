import XCTest
@testable import presq

func simpleResolve(key: String) -> Int {
  return Int(key)!
}

class ImageCacheTests: XCTestCase {

  func checkConsistent<K, V>(_ cache: ImageCache<K, V>) -> Bool {
    // Check that the mru list and the dict have exactly the same set of keys.
    var keySet = Set(cache.values.keys)

    var node_ = cache.mru
    while let node = node_ {
      if !keySet.contains(node.key) {
        print("\(node.key) missing from keyset")
        return false
      }
      keySet.remove(node.key)
      node_ = node.next
    }
    if keySet.count > 0 {
      print("Keys still in key set: \(keySet)")
      return false
    }

    // Check that node->next->prev == node
    node_ = cache.mru
    while let node = node_ {
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

      node_ = node.next
    }

    return true
  }

  func findAndCheck<K, V>(_ cache: ImageCache<K, V>, _ key: K) throws -> V {
    let val = try cache.find(key: key)
    XCTAssert(checkConsistent(cache))
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
}
