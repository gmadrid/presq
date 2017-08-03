import Foundation
import RxSwift

// We don't want a Cocoa dependency, but the easiest way to do this is just
// to pass in the table view. So, we declare this protocol with all of the stuff that we need
// (which is really just reloadData), and we make sure that it's only called on Main thread.
protocol ImageServiceReloadable: class {
  func reloadData()
}

extension NSTableView: ImageServiceReloadable {}

/**
 * A service to manage all of the images found by the crawl.
 * Provides access to the image list via NSTableViewDataSource, and will prompt the table
 * view for update via ImageServiceReloadable.
 */
class ImageService: NSObject {
  private let disposeBag = DisposeBag()
  private let imageInfoC: ConnectableObservable<ImageInfo>

  // The currently selected Image according to selectedRow observable in init.
  var selectedImageS: Observable<ImageInfo?> { return selectedImageSubject.asObservable() }
  private let selectedImageSubject = BehaviorSubject<ImageInfo?>(value: nil)

  // Only access this on main thread
  fileprivate var infos = [ImageInfo]()

  // Only call this on the main thread
  weak var reloadable: ImageServiceReloadable?

  /**
   * Begin crawling the path, returning an ImageInfo for every image file found.
   * The crawl will happen on background thread with QoS .background.
   * Events may fire on any thread.
   */
  init(directory: String, selectedRow: Observable<Int>) {
    let imageFileNameS = Observable.create { (o: AnyObserver<String>) -> Disposable in
      do {
        try crawl(path: directory,
                  process: { o.onNext($0) },
                  shouldDescend: shouldDescend,
                  shouldProcess: shouldProcess)
      } catch {
        // TODO: consider returning an error here.
        print("CAUGHT")
      }
      return Disposables.create()
    }
    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))

    // ImageInfoC is HOT, so we replayAll.
    imageInfoC = imageFileNameS.map { ImageInfo(path: $0) }.replayAll()
    imageInfoC.connect().disposed(by: disposeBag)

    super.init()

    selectedRow
      .subscribe(onNext: { [weak self] row in
        if row >= 0 && row < self?.infos.count ?? 0 {
          // TODO: can you replace all of this with a bind?
          self?.selectedImageSubject.onNext(self?.infos[row])
        } else {
          self?.selectedImageSubject.onNext(nil)
        }
      })
      .disposed(by: disposeBag)

    imageInfoC
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] ii in
        self?.infos.append(ii)
        self?.reloadable?.reloadData()
      })
      .disposed(by: disposeBag)
  }
}

extension ImageService: NSTableViewDataSource {
  public func numberOfRows(in _: NSTableView) -> Int {
    return infos.count
  }

  public func tableView(_: NSTableView, objectValueFor _: NSTableColumn?, row: Int) -> Any? {
    return infos[row].filename
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
