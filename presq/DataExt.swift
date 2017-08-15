import Foundation

extension Data {
  func sha224() -> [UInt8] {
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA224_DIGEST_LENGTH))
    _ = withUnsafeBytes { dataPtr in
      CC_SHA224(dataPtr, CC_LONG(count), &digest)
    }
    return digest
  }
}

extension Array where Element == UInt8 {
  func toHexString() -> String {
    var str = ""
    for byte in self {
      str += String(format: "%02x", byte)
    }
    return str
  }
}
