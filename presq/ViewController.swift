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

enum Error : Swift.Error {
  case GenericError
}

extension CGImage {
  var size: CGSize { return CGSize(width: width, height: height) }
}

func toGray(image: NSImage) throws -> NSImage {
  guard let context = CGContext(data: nil, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8,   bytesPerRow: 0, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
    throw Error.GenericError
  }
  
  guard let cgImageIn = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    throw Error.GenericError
  }

  context.draw(cgImageIn, in: CGRect(origin: CGPoint.zero, size: image.size))
  guard let cgImageOut = context.makeImage() else {
    throw Error.GenericError
  }
  
  return NSImage(cgImage: cgImageOut, size: cgImageOut.size)
}

class ViewController: NSViewController {
  let disposeBag = DisposeBag()

  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var image1View: NSImageView!
  @IBOutlet weak var image2View: NSImageView!
  
  var imageService: ImageService!
  var imageSource: ImageSource!
  var fileListVM: FileListViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    imageService = try! ImageService(directory: "/Users/gmadrid/Documents/Projects/presq/testimages")
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
    
    imageSource.imageName
      .map { name -> NSImage? in
        guard let name = name else { return nil }
        return NSImage(contentsOfFile: name)
      }
      .bind(to: image1View.rx.image)
      .disposed(by: disposeBag)

    imageSource.imageName
      .map { name -> NSImage? in
        guard let name = name else { return nil }
        guard let image =  NSImage(contentsOfFile: name) else { return nil }
        return try? toGray(image: image)
      }
      .bind(to: image2View.rx.image)
      .disposed(by: disposeBag)
  }
}

