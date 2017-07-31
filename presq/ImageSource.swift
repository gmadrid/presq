//
//  ImageSource.swift
//  presq
//
//  Created by George Madrid on 7/29/17.
//  Copyright © 2017 George Madrid. All rights reserved.
//

import Cocoa
import RxSwift

class ImageSource: NSObject {
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

extension ImageSource: NSTableViewDelegate {
  func tableViewSelectionDidChange(_ notification: Notification) {
    let tableView = notification.object as! NSTableView
    selectedRow.onNext(tableView.selectedRow)
  }
}
