import Cocoa
import RxSwift

// We don't want a Cocoa dependency, but the easiest way to do this is just
// to pass in the table view. So, we declare this protocol with all of the stuff that we need
// (which is really just reloadData), and we make sure that it's only called on Main thread.
protocol Reloadable: class {
  func reloadData()
}

extension NSTableView: Reloadable {}

private class MutableImageInfo: ImageInfo {
  let url: URL
  var filename: String { return url.lastPathComponent }

  init(url: URL) {
    self.url = url
  }
}

// This little class is just here so that I can provide an NSTableViewDataSource without
// making the ImageList into an NSObject.
private class ImageListDataSource: NSObject {
  weak var imageList: ImageList?
}

extension ImageListDataSource: NSTableViewDataSource {
  public func numberOfRows(in _: NSTableView) -> Int {
    return imageList?.infoList.count ?? 0
  }

  public func tableView(_: NSTableView, objectValueFor _: NSTableColumn?, row: Int) -> Any? {
    return imageList?.infoList[row].filename
  }
}

/**
 * List of ImageInfos.
 * This list is the primary driver of the UI. It collects:
 * - the list of image URLs,
 * - the ImageInfo objects for each of those URLs,
 * - any hashs (SHA, ahash, dhash, phash) which have been computed.
 *
 * It also drives computation on the image lists on a background thread(s).
 *
 * Access to the list is restricted to the main thread.
 */
class ImageList {
  private let disposeBag = DisposeBag()

  fileprivate var infoList = [MutableImageInfo]()
  var reloadable: Reloadable?
  var dataSource: NSTableViewDataSource = ImageListDataSource()

  class func createImageListForDirectory(_ directory: String) -> ImageList {
    return ImageList(imageURLS: Observable.create { (obs: AnyObserver<URL>) -> Disposable in
      do {
        try crawl(path: directory,
                  process: { path in
                    obs.onNext(URL(fileURLWithPath: path)) },
                  shouldDescend: shouldDescend,
                  shouldProcess: shouldProcess)
      } catch {
        // TODO: consider returning an error here.
        print("CAUGHT")
      }
      return Disposables.create()
    }
    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)))
  }

  init(imageURLS: Observable<URL>) {
    let ilds = ImageListDataSource()
    dataSource = ilds
    ilds.imageList = self

    imageURLS.observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] url in
        self?.infoList.append(MutableImageInfo(url: url))
        self?.reloadable?.reloadData()
        return
      })
      .disposed(by: disposeBag)
  }

  subscript(index: Int) -> ImageInfo? {
    return infoList[index]
  }
}

private func shouldDescend(_ path: String) -> Bool {
  // Skip any "hidden" directories (determined by looking for a '.' prefix.
  let lastComponent = (path as NSString).lastPathComponent
  return !lastComponent.hasPrefix(".")
}

private func shouldProcess(_ path: String) -> Bool {
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
