import Foundation

class ImageInfo {
  let path: String

  // The filename portion of the path (the last path component).
  var filename: String { return (path as NSString).lastPathComponent }

  init(path: String) {
    self.path = path
  }
}
