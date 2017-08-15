import Foundation

protocol ImageInfo: class {
  var url: URL { get }
  var filename: String { get }

  var hash: [UInt8]? { get }
  var ahash: UInt64? { get }
  var dhash: UInt64? { get }
}
