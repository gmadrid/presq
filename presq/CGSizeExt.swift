import CoreGraphics

extension CGSize {
  var rect: CGRect { return CGRect(origin: .zero, size: self) }
}
