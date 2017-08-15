import Foundation

protocol ImageProcessor {
  init(url: URL)
  func process(cgImage: CGImage)
  func mutate() -> ImageInfoMutation?
}

typealias ImageProcessFunc = (_ cache: ImageCache<URL, CGImage>, _ imageInfo: ImageInfo)
  throws -> ImageInfoMutation?

func processSha(cache: ImageCache<URL, CGImage>, imageInfo: ImageInfo) throws -> ImageInfoMutation? {
  do {
    let cgImage = try cache.find(key: imageInfo.url)
    guard let cfData = cgImage.dataProvider?.data else { return nil }
    let data = cfData as NSData as Data
    return .hash(data.sha224())
  } catch {
    return nil
  }
}

func processAhash(cache: ImageCache<URL, CGImage>, imageInfo: ImageInfo) throws -> ImageInfoMutation? {
  do {
    let cgImage = try cache.find(key: imageInfo.url)
    let ahash = try cgImage.ahash()
    return .ahash(ahash)
  } catch {
    return nil
  }
}

func processDhash(cache: ImageCache<URL, CGImage>, imageInfo: ImageInfo) throws -> ImageInfoMutation? {
  do {
    let cgImage = try cache.find(key: imageInfo.url)
    let dhash = try cgImage.dhash()
    return .dhash(dhash)
  } catch {
    return nil
  }
}

class ImageProcessorEngine {
  let imageCache: ImageCache<URL, CGImage>
  let imageList: ImageList

  init(imageList: ImageList, imageCache: ImageCache<URL, CGImage>) {
    self.imageCache = imageCache
    self.imageList = imageList
  }

  var processors: [ImageProcessFunc] = [
    processSha,
    processAhash,
    processDhash
  ]

  func doit(imageInfo: ImageInfo, cgImage _: CGImage) {
    for p in processors {
      do {
        guard let mutation = try p(imageCache, imageInfo) else { break }
        try imageList.mutate(imageInfo: imageInfo, mutation: mutation)
      } catch {
        break
      }
    }
  }
}
