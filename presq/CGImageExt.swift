import Foundation

extension CGImage {
  var size: CGSize { return CGSize(width: width, height: height) }

  func toGray() throws -> CGImage {
    guard let context = CGContext(data: nil,
                                  width: Int(size.width),
                                  height: Int(size.height),
                                  bitsPerComponent: 8,
                                  bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceGray(),
                                  bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
      throw Error.GenericError
    }

    context.draw(self, in: size.rect)
    guard let cgImageOut = context.makeImage() else {
      throw Error.GenericError
    }
    return cgImageOut
  }

  func scale(to scaleSize: CGSize) throws -> CGImage {
    guard let context = CGContext(data: nil,
                                  width: Int(scaleSize.width),
                                  height: Int(scaleSize.height),
                                  bitsPerComponent: self.bitsPerComponent,
                                  bytesPerRow: 0,
                                  space: colorSpace!,
                                  bitmapInfo: bitmapInfo.rawValue) else {
      throw Error.GenericError
    }

    context.draw(self, in: scaleSize.rect)
    guard let cgImageOut = context.makeImage() else {
      throw Error.GenericError
    }
    return cgImageOut
  }

  func intensities() throws -> [UInt8] {
    let totalBytes = height * width
    var result = Array(repeating: UInt8(0), count: totalBytes)

    let space = CGColorSpaceCreateDeviceGray()
    guard let context = CGContext(data: &result,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: width,
                                  space: space,
                                  bitmapInfo: bitmapInfo.rawValue) else {
      throw Error.GenericError
    }
    context.draw(self, in: size.rect)
    return result
  }

  func ahash() throws -> UInt64 {
    let grayImage = try toGray()
    let smallImage = try grayImage.scale(to: CGSize(width: 8, height: 8))
    let intensityValues = try smallImage.intensities()

    // Compute average in UInt16 to avoid overflow.
    let avgValue =
      intensityValues.reduce(UInt16(0)) { $0 + UInt16($1) } / UInt16(intensityValues.count)

    let hashBits = intensityValues.map { UInt16($0) < avgValue ? 0 : 1 }
    let hash = hashBits.reduce(UInt64(0)) { ($0 << 1) | UInt64($1) }

    return hash
  }
}
