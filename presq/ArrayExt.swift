import Foundation

extension Array where Element == UInt8 {
  func toHexString() -> String {
    var str = ""
    for byte in self {
      str += String(format: "%02x", byte)
    }
    return str
  }
}
