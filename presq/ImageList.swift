import Cocoa
import RxSwift

// We don't want a Cocoa dependency, but the easiest way to do this is just
// to pass in the table view. So, we declare this protocol with all of the stuff that we need
// (which is really just reloadData), and we make sure that it's only called on Main thread.
protocol Reloadable: class {
  func reloadData()
}

extension NSTableView: Reloadable {}

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

enum ImageInfoMutation {
  case hash([UInt8])
  case ahash(UInt64)
  case dhash(UInt64)
}

private class MutableImageInfo: ImageInfo {
  let url: URL
  var filename: String { return url.lastPathComponent }
  private(set) var hash: [UInt8]?
  private(set) var ahash: UInt64?
  private(set) var dhash: UInt64?

  init(url: URL) {
    self.url = url
  }

  func mutate(mutation: ImageInfoMutation) {
    switch mutation {
    case let .hash(hsh):
      hash = hsh
    case let .ahash(ahsh):
      ahash = ahsh
    case let .dhash(dhsh):
      dhash = dhsh
    }
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

  /** An object implementing the Reloadable protocol to be invoked when the list changes. */
  var reloadable: Reloadable?

  /** An ObjC object that can act as a data source for an NSTableView. */
  private(set) var dataSource: NSTableViewDataSource = ImageListDataSource()

  private let infosCreatedSubject = PublishSubject<ImageInfo>()
  var infosCreatedS: Observable<ImageInfo> { return infosCreatedSubject.asObservable() }

  private let infosModifiedSubject = PublishSubject<ImageInfo>()
  var infosModifiedS: Observable<ImageInfo> { return infosModifiedSubject.asObservable() }

  init(imageURLS: Observable<URL>) {
    let ilds = ImageListDataSource()
    dataSource = ilds
    ilds.imageList = self

    imageURLS
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] url in
        let imageInfo = MutableImageInfo(url: url)
        self?.infoList.append(imageInfo)

        // Add to the infosCreated sequence _after_ it has been added to the list.
        self?.infosCreatedSubject.onNext(imageInfo)

        self?.reloadable?.reloadData()
        return
      })
      .disposed(by: disposeBag)
  }

  subscript(index: Int) -> ImageInfo? {
    return infoList[index]
  }

  func mutate(imageInfo: ImageInfo, mutation: ImageInfoMutation) throws {
    guard let mutable = imageInfo as? MutableImageInfo else {
      throw Error.genericError
    }
    DispatchQueue.main.async { [weak self] in
      mutable.mutate(mutation: mutation)
      self?.infosModifiedSubject.onNext(imageInfo)
    }
  }
}
