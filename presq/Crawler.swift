//
//  Crawler.swift
//  presq
//
//  Created by George Madrid on 7/24/17.
//  Copyright © 2017 George Madrid. All rights reserved.
//

import Foundation

protocol Crawler {
  func shouldDescend(dirname: String) -> Bool
  func shouldProcess(filename: String) -> Bool
  func process(filename: String) throws
  func done()
}

extension Crawler {
  func shouldDescend(dirname: String) -> Bool { return true }
  func shouldProcess(filename: String) -> Bool { return true }
  func done() {}
}

func crawl(_ crawler: Crawler, _ path: String) throws {
  let manager = FileManager.default
  guard let seq = manager.enumerator(atPath: path) else {
    throw Error.GenericError
  }

  for val in seq {
    let fragment = val as! String
    let fullPath = (path as NSString).appendingPathComponent(fragment) as String
    var isDir : ObjCBool = false

    guard manager.fileExists(atPath: fullPath, isDirectory: &isDir) else { continue }
    
    if isDir.boolValue {
      if !crawler.shouldDescend(dirname: fullPath) {
        seq.skipDescendants()
      }
    } else {
      if crawler.shouldProcess(filename: fullPath) {
        try crawler.process(filename: fullPath)
      }
    }
  }
  crawler.done()
}
