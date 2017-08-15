import Cocoa
import CoreGraphics
import RxSwift
import RxCocoa

enum Error: Swift.Error {
  case genericError
}

private func hashToImage(hash: UInt64?) -> NSImage? {
  guard let hash = hash,
    let blocks = try? imageForBitmap(bitmap: hash, width: 8, height: 8, scale: 40) else {
    return nil
  }
  return NSImage(cgImage: blocks)
}

class ViewController: NSViewController {
  private let disposeBag = DisposeBag()

  @IBOutlet private weak var tableView: NSTableView!
  @IBOutlet private weak var image1View: NSImageView!
  @IBOutlet private weak var image2View: NSImageView!
  @IBOutlet private weak var image3View: NSImageView!

  private var imageCache = ImageCache<URL, CGImage>(maxSize: 50) { key in
    guard let image = NSImage(contentsOf: key),
      let cgImage = image.cgImage
    else { throw Error.genericError }
    return cgImage
  }

  private var imageList: ImageList!
  private var tableDelegate: TableDelegateWrapper!

  override func viewDidDisappear() {
    super.viewDidDisappear()

    // Close the app when we close the window.
    NSApplication.shared().terminate(nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Set up the table delegate to propagate state changes from the table view.
    tableDelegate = TableDelegateWrapper(tableView: tableView)

    // Prepare the image crawl on background thread, but it's hot, so defer subs until all set up.
    let dir = "/Users/gmadrid/Desktop/presq/testimages/clean"
    //    let dir = "/Users/gmadrid/Desktop/presq/testimages"
    // let dir = "/Users/gmadrid/Dropbox/Images/Adult/Images"
    let imageNames = imageFileSource(from: dir)
      .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
      .publish()

    // Link the table to the image list and vice versa.
    imageList = ImageList(imageURLS: imageNames)
    tableView.dataSource = imageList.dataSource
    imageList.reloadable = tableView

    let engine = ImageProcessorEngine(imageList: imageList, imageCache: imageCache)

    imageList.infosCreatedS
      .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
      .subscribe(onNext: { [weak self] imageInfo in
        guard let this = self,
          let cgImage = try? this.imageCache.find(key: imageInfo.url) else { return }
        engine.doit(imageInfo: imageInfo, cgImage: cgImage)
      })
      .disposed(by: disposeBag)

    imageNames.connect().disposed(by: disposeBag)

    let currentImageInfoS = tableDelegate.selectedRowS
      .map { [weak self] rowNum in
        return self?.imageList[rowNum]
      }

    let cgImageS = currentImageInfoS.map { [weak self] imageInfo -> CGImage? in
      guard let this = self,
        let imageInfo = imageInfo,
        let cgImage = try? this.imageCache.find(key: imageInfo.url) else { return nil }
      return cgImage
    }

    let imageS = cgImageS.map { cgImage -> NSImage? in
      guard let cgImage = cgImage else { return nil }
      return NSImage(cgImage: cgImage)
    }
    imageS.bind(to: image1View.rx.image).disposed(by: disposeBag)

    currentImageInfoS
      .map { hashToImage(hash: $0?.ahash) }
      .bind(to: image2View.rx.image).disposed(by: disposeBag)

    currentImageInfoS
      .map { hashToImage(hash: $0?.dhash) }
      .bind(to: image3View.rx.image).disposed(by: disposeBag)
  }
}
