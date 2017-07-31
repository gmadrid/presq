import Cocoa

extension NSImage {
  var cgImage: CGImage? {
    return cgImage(forProposedRect: nil, context: nil, hints: nil)
  }

  func toGray() throws -> NSImage {
    guard let gray = try cgImage?.toGray() else {
      throw Error.GenericError
    }
    return NSImage(cgImage: gray, size: gray.size)
  }
}
