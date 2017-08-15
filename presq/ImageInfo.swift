import Foundation

enum ImageInfoMutation {
  case hash([UInt8])
  case ahash(UInt64)
}

protocol ImageInfo {
  var url: URL { get }
  var filename: String { get }

  var hash: [UInt8]? { get }
  var ahash: UInt64? { get }
}

class MutableImageInfo: ImageInfo {
  let url: URL
  var filename: String { return url.lastPathComponent }
  private(set) var hash: [UInt8]?
  private(set) var ahash: UInt64?

  init(url: URL) {
    self.url = url
  }

  func mutate(mutation: ImageInfoMutation) {
    switch mutation {
    case let .hash(hsh):
      hash = hsh
    case let .ahash(ahsh):
      ahash = ahsh
    }
  }
}
