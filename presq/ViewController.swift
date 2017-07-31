//
//  ViewController.swift
//  presq
//
//  Created by George Madrid on 7/24/17.
//  Copyright © 2017 George Madrid. All rights reserved.
//

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
  var imageSource: ImageSource!
  var fileListVM: FileListViewModel!

  func createImageService() throws -> ImageService {
    do {
      imageService = try ImageService(directory: "/Users/gmadrid/Documents/Projects/presq/testimages")
      return imageService
    } catch {}

    imageService = try ImageService(directory: "/Users/gmadrid/Desktop/presq/testimages/clean")
    return imageService
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    imageService = try! createImageService()
    imageSource = ImageSource(filenames: imageService.filenames)
    fileListVM = FileListViewModel(filenamesS: imageService.filenames)
    tableView.dataSource = fileListVM
    tableView.delegate = imageSource

    fileListVM.filenamesChanged
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] _ in
        self?.tableView.reloadData()
      })
      .disposed(by: disposeBag)

    let imageS = imageSource.imageName
      .map { name -> NSImage? in
        guard let name = name else { return nil }
        return NSImage(contentsOfFile: name)
      }

    let cgImageS = imageS.map { $0?.cgImage }
    let bwImageS = cgImageS.map { cgImage -> CGImage? in
      guard let cgImage = cgImage else { return nil }
      return try? cgImage.toGray()
    }
    let smallImageS = bwImageS.map { cgImage -> CGImage? in
      guard let cgImage = cgImage else { return nil }
      return try? cgImage.scale(to: CGSize(width: 8, height: 8))
    }

    imageS.bind(to: image1View.rx.image).disposed(by: disposeBag)
    smallImageS
      .map { cgImage -> NSImage? in
        guard let cgImage = cgImage else { return nil }
        let newSize = CGSize(width: cgImage.size.width * 40, height: cgImage.size.height * 40)
        return NSImage(cgImage: cgImage, size: newSize) }
      .bind(to: image2View.rx.image).disposed(by: disposeBag)
  }
}
