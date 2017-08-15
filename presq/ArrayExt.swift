//
//  ArrayExt.swift
//  presq
//
//  Created by George Madrid on 8/15/17.
//  Copyright © 2017 George Madrid. All rights reserved.
//

import Foundation

extension Array where Element == UInt8 {
  func toHexString() -> String {
    var str = ""
    for byte in self {
      str += String(format: "%02x", byte)
    }
    return str
  }
}
