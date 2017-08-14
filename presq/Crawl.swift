import Foundation
import RxSwift

/**
 * Crawl all subdirectories of path and process all files.
 * Caller provides closures to determine specific behavior.
 *
 * path - The root directory for the crawl.
 * process - Process the supplied path.
 * shouldDescend - Predicate to determine whether the crawl should recurse into a subdirectory.
 * shouldProcess - Predicate to determine whether a file should be processed.
 */
func crawl(path: String,
           process: (String) throws -> Void,
           shouldDescend: (String) -> Bool,
           shouldProcess: (String) -> Bool) throws {
  let manager = FileManager.default
  // TODO: throw something real and informative here.
  guard let seq = manager.enumerator(atPath: path) else {
    throw Error.genericError
  }

  for val in seq {
    // TODO: Should you log or error or something here?
    guard let stringVal = val as? String else { continue }

    let fullPath = (path as NSString).appendingPathComponent(stringVal)

    var isDir: ObjCBool = false
    guard manager.fileExists(atPath: fullPath, isDirectory: &isDir) else { continue }

    if isDir.boolValue {
      if !shouldDescend(fullPath) {
        seq.skipDescendants()
      }
    } else if shouldProcess(fullPath) {
      try process(fullPath)
    }
  }
}

func imageFileSource(from directory: String) -> Observable<URL> {
  func shouldDescend(_ path: String) -> Bool {
    // Skip any "hidden" directories (determined by looking for a '.' prefix.
    let lastComponent = (path as NSString).lastPathComponent
    return !lastComponent.hasPrefix(".")
  }

  func shouldProcess(_ path: String) -> Bool {
    // We only want to process image files.
    let fileExtension = (path as NSString).pathExtension

    guard let fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                              fileExtension as CFString,
                                                              nil) else {
      return false
    }
    defer { fileUTI.release() }

    return UTTypeConformsTo(fileUTI.takeUnretainedValue(), kUTTypeImage)
  }

  return Observable.create { (obs: AnyObserver<URL>) -> Disposable in
    do {
      try crawl(path: directory,
                process: { path in
                  obs.onNext(URL(fileURLWithPath: path)) },
                shouldDescend: shouldDescend,
                shouldProcess: shouldProcess)
    } catch {
      // TODO: consider returning an error here.
      print("CAUGHT")
    }
    return Disposables.create()
  }
}
