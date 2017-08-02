import Cocoa

import RxSwift

func shouldDescend(_ path: String) -> Bool {
  // Skip any "hidden" directories (determined by looking for a '.' prefix.
  let lastComponent = (path as NSString).lastPathComponent
  return !lastComponent.hasPrefix(".")
}

func shouldProcess(_ path: String) -> Bool {
  // We only want to process image files.
  let fileExtension = (path as NSString).pathExtension
  
  guard let fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                            fileExtension as CFString,
                                                            nil) else {
                                                              return false
  }
  defer { fileUTI.release() }
  
  return UTTypeConformsTo(fileUTI.takeUnretainedValue(), kUTTypeImage)
}

class ImageInfo {}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  private let disposeBag = DisposeBag()
  
  var imageNamesS: Observable<String>!
  var imageInfoS: Observable<ImageInfo>!

  func applicationWillFinishLaunching(_ notification: Notification) {
    print("DOING THIS")
    let imageFileNameS = Observable.create { (observer: AnyObserver<String>) -> Disposable in
      do {
        try crawl(path: "/Users/gmadrid/Dropbox/Images/",
                  process: { observer.onNext($0) },
                  shouldDescend: { shouldDescend($0) },
                  shouldProcess: { shouldProcess($0) })
      } catch {
        print("CAUGHT")
      }
      return Disposables.create()
      }
      .debug()
      .subscribeOn(ConcurrentDispatchQueueScheduler(qos: DispatchQoS.background))
    imageNamesS = imageFileNameS
    
    let imageInfoC = imageFileNameS.map { _ in return ImageInfo() }.replayAll()
    imageInfoS = imageInfoC.asObservable()
    
    imageInfoC.connect().disposed(by: disposeBag)
  }

  func applicationWillTerminate(_: Notification) {
    // Insert code here to tear down your application
  }
}
