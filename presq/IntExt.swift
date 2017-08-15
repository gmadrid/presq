import Foundation

extension Int {
  func times(_ fun: () -> Void) {
    for _ in 0 ..< self { fun() }
  }
}
