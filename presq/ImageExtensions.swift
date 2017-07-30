//
//  ImageExtensions.swift
//  presq
//
//  Created by George Madrid on 7/29/17.
//  Copyright © 2017 George Madrid. All rights reserved.
//

import CoreGraphics
import Cocoa

extension CGSize {
  var rect: CGRect { return CGRect(origin: .zero, size: self) }
}

extension CGImage {
  var size: CGSize { return CGSize(width: width, height: height) }
  
  func toGray() throws -> CGImage {
    guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8,   bytesPerRow: 0, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
      throw Error.GenericError
    }
    
    context.draw(self, in: size.rect)
    guard let cgImageOut = context.makeImage() else {
      throw Error.GenericError
    }
    return cgImageOut
  }
  
  func scale(to scaleSize: CGSize) throws -> CGImage {
    guard let context = CGContext(data: nil, width: Int(scaleSize.width), height: Int(scaleSize.height), bitsPerComponent:self.bitsPerComponent, bytesPerRow: 0, space: colorSpace!, bitmapInfo: bitmapInfo.rawValue) else {
      throw Error.GenericError
    }
    
    context.draw(self, in: scaleSize.rect)
    guard let cgImageOut = context.makeImage() else {
      throw Error.GenericError
    }
    return cgImageOut
  }
}

extension NSImage {
  var cgImage: CGImage? {
    return cgImage(forProposedRect: nil, context: nil, hints: nil)
  }
  
  func toGray() throws -> NSImage {
    guard let gray = try cgImage?.toGray() else {
      throw Error.GenericError
    }
    return NSImage(cgImage: gray, size: gray.size)
  }
}
