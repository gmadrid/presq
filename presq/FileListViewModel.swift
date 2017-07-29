//
//  FileListViewModel.swift
//  presq
//
//  Created by George Madrid on 7/27/17.
//  Copyright © 2017 George Madrid. All rights reserved.
//

import Foundation
import RxSwift

class FileListViewModel : NSObject {
  private var disposeBag = DisposeBag()
  
  fileprivate var filenames: [String] = [] {
    didSet {
      filenamesChangedSubject.onNext(())
    }
  }
  var filenamesChanged: Observable<()> { return filenamesChangedSubject.asObservable() }
  private let filenamesChangedSubject = PublishSubject<()>()
  
  init(filenamesS: Observable<[String]>) {
    super.init()
    filenamesS
      .subscribe(onNext: { [weak self] fns in
        self?.filenames = fns
      })
      .disposed(by: disposeBag)
  }
}

extension FileListViewModel: NSTableViewDataSource {
  public func numberOfRows(in _: NSTableView) -> Int {
    return filenames.count
  }
  
  public func tableView(_: NSTableView, objectValueFor _: NSTableColumn?, row: Int) -> Any? {
    return (filenames[row] as NSString).lastPathComponent
  }
}
