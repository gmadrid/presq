import Foundation
import RxSwift

class ImageService: Crawler {
  var filenames: Observable<[String]> {
    return filenames_.asObservable()
  }
  private let filenames_: BehaviorSubject<[String]>
  private var filenamesArray = [String]()
  
  init(directory: String) throws {
    filenames_ = BehaviorSubject(value: [])
    // TODO: move this to a background thread.
    try crawl(self, directory)
  }
  
  func shouldDescend(dirname: String) -> Bool {
    // Skip any "hidden" directories (determined by looking for a '.' prefix.
    let lastComponent = (dirname as NSString).lastPathComponent
    if lastComponent.hasPrefix(".") {
      print("Skipping: \(lastComponent)")
      return false
    }
    return true
  }
  
  func shouldProcess(filename: String) -> Bool {
    // We only want to process image files.
    let fileExtension = (filename as NSString).pathExtension
    
    guard let fileUTI = UTTypeCreatePreferredIdentifierForTag(
      kUTTagClassFilenameExtension, fileExtension as CFString, nil) else {
        return false
    }
    defer {
      fileUTI.release()
    }
    
    return UTTypeConformsTo(fileUTI.takeUnretainedValue(), kUTTypeImage)
  }

  func process(filename: String) throws {
    filenamesArray.append(filename)
    filenames_.onNext(filenamesArray)
  }
}
