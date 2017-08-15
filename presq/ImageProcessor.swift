import Foundation

protocol ImageProcessor {
  init(url: URL)
  func process(cgImage: CGImage)
  func mutate() -> ImageInfoMutation?
}

class Sha256Processor: ImageProcessor {
  let url: URL
  var hash: [UInt8]?

  required init(url: URL) { self.url = url }

  func process(cgImage: CGImage) {
    guard let cfData = cgImage.dataProvider?.data else { return }

    let data = cfData as NSData as Data
    hash = data.sha224()
  }

  func mutate() -> ImageInfoMutation? {
    guard let hash = hash else { return nil }
    return .hash(hash)
  }
}

class AhashProcessor: ImageProcessor {
  let url: URL
  var ahash: UInt64?

  required init(url: URL) { self.url = url }

  func process(cgImage: CGImage) {
    ahash = try? cgImage.ahash()
  }

  func mutate() -> ImageInfoMutation? {
    guard let ahash = ahash else { return nil }
    return .ahash(ahash)
  }
}

class ImageProcessorEngine {
  let imageList: ImageList

  init(imageList: ImageList) {
    self.imageList = imageList
  }

  var processors: [ImageProcessor.Type] = [
    Sha256Processor.self,
    AhashProcessor.self,
  ]

  func doit(imageInfo: ImageInfo, cgImage: CGImage) {
    for p in processors {
      let pp = p.init(url: imageInfo.url)
      pp.process(cgImage: cgImage)
      if let mutation = pp.mutate() {
        try? imageList.mutate(imageInfo: imageInfo, mutation: mutation)
      }
    }
  }
}
