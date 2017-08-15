import Foundation

extension Sequence where Iterator.Element == UInt8 {
  func toBitMap() -> UInt64 {
    return reduce(0) { ($0 << 1) | UInt64($1) }
  }
}

extension Sequence where Iterator.Element: UInt64Convertible {
  // Compute sum in UInt64 to avoid overflow.
  func sum() -> UInt64 {
    return reduce(0) { $0 + $1.toUInt64() }
  }

  func avg() -> CGFloat {
    var total: UInt64 = 0
    var maxIndex = 0
    for (index, val) in enumerated() {
      total += val.toUInt64()
      maxIndex = index
    }
    return CGFloat(total) / CGFloat(UInt64(maxIndex))
  }
}
