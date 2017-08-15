import XCTest
@testable import presq

class DataExtTests: XCTestCase {

  // All of this test data from https://www.di-mgt.com.au/sha_testvectors.html
  func test24bits() {
    let bytes = "abc".data(using: .ascii)!

    XCTAssertEqual("23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7",
                   bytes.sha224().toHexString())
  }

  func test0bits() {
    let bytes = "".data(using: .ascii)!

    XCTAssertEqual("d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f",
                   bytes.sha224().toHexString())
  }

  func test448bits() {
    let bytes = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq".data(using: .ascii)!

    XCTAssertEqual("75388b16512776cc5dba5da1fd890150b0c6455cb4f58b1952522525",
                   bytes.sha224().toHexString())
  }

  func test896bits() {
    let bytes = "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu".data(using: .ascii)!

    XCTAssertEqual("c97ca9a559850ce97a04a96def6d99a9e0e0e2ab14e6b8df265fc0b3",
                   bytes.sha224().toHexString())
  }

  func test1000000a() {
    // 1,000,000 a's
    let data = Data([UInt8](repeating: 0x61, count: 1_000_000))

    XCTAssertEqual("20794655980c91d8bbb4c1ea97618a4bf03f42581948b2ee4ee7ad67",
                   data.sha224().toHexString())
  }
}
