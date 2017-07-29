//
//  ViewController.swift
//  presq
//
//  Created by George Madrid on 7/24/17.
//  Copyright © 2017 George Madrid. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class ImageSource : NSObject {
  var imageName: Observable<String?>
  let imageSubject = BehaviorSubject<NSImage?>(value: nil)
  
  fileprivate let selectedRow = BehaviorSubject<Int>(value: 0)
  
  init(filenames: Observable<[String]>) {
    imageName = Observable.combineLatest(selectedRow, filenames) { row, fns in
      if row >= fns.count { return nil }
      return fns[row]
    }
    
    super.init()
    
  }
}

extension ImageSource : NSTableViewDelegate {
  func tableViewSelectionDidChange(_ notification: Notification) {
    let tableView = notification.object as! NSTableView
    selectedRow.onNext(tableView.selectedRow)
  }
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
        return NSImage(contentsOfFile: name)
      }
      .bind(to: image2View.rx.image)
      .disposed(by: disposeBag)
  }
}

