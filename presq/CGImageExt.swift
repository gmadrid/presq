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
      throw Error.genericError
    }

    context.draw(self, in: size.rect)
    guard let cgImageOut = context.makeImage() else {
      throw Error.genericError
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
      throw Error.genericError
    }

    context.draw(self, in: scaleSize.rect)
    guard let cgImageOut = context.makeImage() else {
      throw Error.genericError
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
      throw Error.genericError
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

func blockyScaledImage(values: [UInt8], width: Int, height: Int, scale: Int) throws -> CGImage {
  guard width > 0 && height > 0 && scale > 0 else {
    throw Error.genericError
  }
  guard values.count >= width * height else {
    throw Error.genericError
  }

  let totalBytes = width * height * scale * scale
  var bytes = [UInt8]()
  bytes.reserveCapacity(totalBytes)

  var row = [UInt8]()
  row.reserveCapacity(width * scale)

  var iter = values.makeIterator()

  for _ in 0 ..< height {
    for _ in 0 ..< width {
      guard let byte = iter.next() else {
        throw Error.genericError
      }

      scale.times { row.append(byte) }
    }

    scale.times { bytes.append(contentsOf: row) }
    row.removeAll(keepingCapacity: true)
  }

  let space = CGColorSpaceCreateDeviceGray()
  guard let context = CGContext(data: &bytes,
                                width: Int(width * scale),
                                height: Int(height * scale),
                                bitsPerComponent: 8,
                                bytesPerRow: Int(width * scale),
                                space: space,
                                bitmapInfo: CGImageAlphaInfo.none.rawValue),
    let cgImageOut = context.makeImage() else {
    throw Error.genericError
  }
  return cgImageOut
}

func imageForBitmap(bitmap: UInt64, width: Int, height: Int, scale: Int) throws -> CGImage {
  var bytes = [UInt8]()
  bytes.reserveCapacity(64)

  var bits = bitmap
  for _ in 0 ..< 64 {
    let byte: UInt8 = bits & 0x8000_0000_0000_0000 == 0 ? 0x00 : 0xFF
    bits = bits << 1
    bytes.append(byte)
  }

  return try blockyScaledImage(values: bytes, width: width, height: height, scale: scale)
}
