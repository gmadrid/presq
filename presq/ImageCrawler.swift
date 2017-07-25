//
//  ImageCrawler.swift
//  presq
//
//  Created by George Madrid on 7/24/17.
//  Copyright © 2017 George Madrid. All rights reserved.
//

import Foundation

class ImageCrawler : Crawler {
  func shouldProcess(filename: String) -> Bool {
    // We only want to process image files.
    let fileExtension = (filename as NSString).pathExtension

    guard let fileUTI = UTTypeCreatePreferredIdentifierForTag(
        kUTTagClassFilenameExtension, fileExtension as CFString, nil) else {
      return false
    }

    defer {
      fileUTI.release()
    }

    return UTTypeConformsTo(fileUTI.takeUnretainedValue(), kUTTypeImage)
  }
  
  func process(filename: String) throws {
    print(filename)
  }
}
