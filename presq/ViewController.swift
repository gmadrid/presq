import Cocoa
import CoreGraphics
import RxSwift
import RxCocoa

enum Error: Swift.Error {
  case genericError
}

class ViewController: NSViewController {
  private let disposeBag = DisposeBag()

  @IBOutlet private weak var tableView: NSTableView!
  @IBOutlet private weak var image1View: NSImageView!
  @IBOutlet private weak var image2View: NSImageView!

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

    // Start up the image crawl.
    let dir = "/Users/gmadrid/Desktop/presq/testimages/clean"
    //    let dir = "/Users/gmadrid/Desktop/presq/testimages"
    //    let dir = "/Users/gmadrid/Dropbox/Images/Adult/Images"
    imageList = ImageList.createImageListForDirectory(dir)

    // Link the table to the image list and vice versa.
    tableView.dataSource = imageList.dataSource
    imageList.reloadable = tableView

    let imageInfoS = tableDelegate.selectedRowS
      .map { [weak self] rowNum in
        return self?.imageList[rowNum]
      }

    let cgImageS = imageInfoS.map { [weak self] imageInfo -> CGImage? in
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

    let bwImageS = cgImageS.map { cgImage -> CGImage? in
      guard let cgImage = cgImage else { return nil }
      return try? cgImage.toGray()
    }
    let smallImageS = bwImageS.map { cgImage -> CGImage? in
      guard let cgImage = cgImage else { return nil }
      return try? cgImage.scale(to: CGSize(width: 8, height: 8))
    }

    smallImageS
      .map { cgImage -> NSImage? in
        guard let cgImage = cgImage,
          let ahash = try? cgImage.ahash(),
          let blocks = try? imageForBitmap(bitmap: ahash, width: 8, height: 8, scale: 40)
        else { return nil }
        return NSImage(cgImage: blocks)
      }
      .bind(to: image2View.rx.image).disposed(by: disposeBag)
  }
}
