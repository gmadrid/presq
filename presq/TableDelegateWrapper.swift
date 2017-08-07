import Cocoa
import RxSwift

class TableDelegateWrapper: NSObject {
  fileprivate let selectedRowSubject = PublishSubject<Int>()
  var selectedRowS: Observable<Int> { return selectedRowSubject.asObservable() }

  fileprivate weak var tableView: NSTableView?

  init(tableView: NSTableView) {
    self.tableView = tableView

    super.init()

    tableView.delegate = self
  }
}

extension TableDelegateWrapper: NSTableViewDelegate {
  func tableViewSelectionDidChange(_ notification: Notification) {
    guard let tableView = notification.object as? NSTableView else { return }
    selectedRowSubject.onNext(tableView.selectedRow)
  }
}
