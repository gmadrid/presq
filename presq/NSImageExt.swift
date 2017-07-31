import Cocoa

extension NSImage {
  var cgImage: CGImage? {
    return cgImage(forProposedRect: nil, context: nil, hints: nil)
  }

  convenience init(cgImage: CGImage) {
    self.init(cgImage: cgImage, size: cgImage.size)
  }
}
