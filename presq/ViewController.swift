import Cocoa
import CoreGraphics
import RxSwift
import RxCocoa

enum Error: Swift.Error {
  case GenericError
}

class ViewController: NSViewController {
  let disposeBag = DisposeBag()

  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var image1View: NSImageView!
  @IBOutlet weak var image2View: NSImageView!

  var imageService: ImageService!
  var tableDelegate: TableDelegateWrapper!
  //  var imageSource: ImageSource!
  //  var fileListVM: FileListViewModel!

  func createImageService(selectedRowS: Observable<Int>) throws -> ImageService {
    let images = ImageService(directory: "/Users/gmadrid/Desktop/presq/testimages/clean",
                              //    let images = ImageService(directory: "/Users/gmadrid/Desktop/presq/testimages",
                              //    let images = ImageService(directory: "/Users/gmadrid/Dropbox/Images/Adult/Images",
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

    let imageS = imageService.selectedImageS
      .map { info -> NSImage? in
        guard let info = info else { return nil }
        return NSImage(contentsOfFile: info.path)
      }

    imageS.bind(to: image1View.rx.image).disposed(by: disposeBag)

    //    imageSource = ImageSource(filenames: imageService.filenames)
    //    fileListVM = FileListViewModel(filenamesS: imageService.filenames)
    //    tableView.dataSource = fileListVM
    //    tableView.delegate = imageSource

    //    fileListVM.filenamesChanged
    //      .observeOn(MainScheduler.instance)
    //      .subscribe(onNext: { [weak self] _ in
    //        self?.tableView.reloadData()
    //      })
    //      .disposed(by: disposeBag)
    //
    //    let imageS = imageSource.imageName
    //      .map { name -> NSImage? in
    //        guard let name = name else { return nil }
    //        return NSImage(contentsOfFile: name)
    //      }
    //
    //    let cgImageS = imageS.map { $0?.cgImage }
    //    let bwImageS = cgImageS.map { cgImage -> CGImage? in
    //      guard let cgImage = cgImage else { return nil }
    //      return try? cgImage.toGray()
    //    }
    //    let smallImageS = bwImageS.map { cgImage -> CGImage? in
    //      guard let cgImage = cgImage else { return nil }
    //      return try? cgImage.scale(to: CGSize(width: 8, height: 8))
    //    }
    //
    //    imageS.bind(to: image1View.rx.image).disposed(by: disposeBag)
    //    smallImageS
    //      .map { cgImage -> NSImage? in
    //        guard let cgImage = cgImage else { return nil }
    //        let ahash = try! cgImage.ahash()
    //        let blocks = try! imageForBitmap(bitmap: ahash, width: 8, height: 8, scale: 40)
    //        return NSImage(cgImage: blocks)
    //      }
    //      .bind(to: image2View.rx.image).disposed(by: disposeBag)
  }
}
