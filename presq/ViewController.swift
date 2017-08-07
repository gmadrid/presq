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

  private var imageService: ImageService!
  private var tableDelegate: TableDelegateWrapper!

  private func createImageService(selectedRowS: Observable<Int>) throws -> ImageService {
    //    let images = ImageService(directory: "/Users/gmadrid/Desktop/presq/testimages/clean",
    //    let images = ImageService(directory: "/Users/gmadrid/Desktop/presq/testimages",
    let images = ImageService(directory: "/Users/gmadrid/Dropbox/Images/Adult/Images",
                              selectedRow: selectedRowS)
    return images
  }

  override func viewDidDisappear() {
    super.viewDidDisappear()

    // Close the app when we close the window.
    NSApplication.shared().terminate(nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    tableDelegate = TableDelegateWrapper(tableView: tableView)

    imageService = try! createImageService(selectedRowS: tableDelegate.selectedRowS)
    tableView.dataSource = imageService
    imageService.reloadable = tableView

    let imageS = imageService.selectedInfoS
      .map { [weak self] info -> NSImage? in
        guard let info = info,
          let imageService = self?.imageService,
          let cgImage = try? imageService.loadImage(filename: info.path)
        else { return nil }
        return NSImage(cgImage: cgImage)
      }

    imageS.bind(to: image1View.rx.image).disposed(by: disposeBag)

    let cgImageS = imageS.map { $0?.cgImage }
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
