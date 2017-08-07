import Foundation

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
    guard let stringVal = val as? String else { continue; }

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
