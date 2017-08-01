import Foundation

protocol UInt64Convertible {
  func toUInt64() -> UInt64
}

extension Int: UInt64Convertible {
  func toUInt64() -> UInt64 {
    return UInt64(self)
  }
}

extension UInt8: UInt64Convertible {
  func toUInt64() -> UInt64 {
    return UInt64(self)
  }
}


