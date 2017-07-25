//
//  ViewController.swift
//  presq
//
//  Created by George Madrid on 7/24/17.
//  Copyright © 2017 George Madrid. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    let crawler = ImageCrawler()
    try! crawl(crawler, "/Users/gmadrid/Dropbox/Images")
  }

  override var representedObject: Any? {
    didSet {
    // Update the view, if already loaded.
    }
  }


}

