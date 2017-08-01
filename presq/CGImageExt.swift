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
    let smallImage = try toGray().scale(to: CGSize(width: 8, height: 8))
    let intensityValues = try smallImage.intensities()

    let avgValue = intensityValues.avg()

    let hashBits = intensityValues.map { UInt8(CGFloat($0) < avgValue ? 0 : 1) }
    let hash = hashBits.toBitMap()

    return hash
  }  
}

extension Sequence where Iterator.Element == UInt8 {
  func toBitMap() -> UInt64 {
    return reduce(0) { ($0 << 1) | UInt64($1) }
  }
}

extension Sequence where Iterator.Element: UInt64Convertible {
  // Compute sum in UInt64 to avoid overflow.
  func sum() -> UInt64 {
    return reduce(0) { $0 + $1.toUInt64() }
  }

  func avg() -> CGFloat {
    var total: UInt64 = 0
    var maxIndex = 0
    for (index, val) in enumerated() {
      total += val.toUInt64()
      maxIndex = index
    }
    return CGFloat(total) / CGFloat(UInt64(maxIndex))
  }
}
