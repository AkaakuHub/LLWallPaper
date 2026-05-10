import Foundation

public final class AppLogger: @unchecked Sendable {
  public init() {}

  public func error(_ message: String, _ error: Error? = nil) {
    let detail = error.map { " \($0.localizedDescription)" } ?? ""
    write("ERROR \(message)\(detail)")
  }

  public func info(_ message: String) {
    write("INFO \(message)")
  }

  private func write(_ line: String) {
    do {
      try AppPaths.ensureDirectories()
      let formatter = ISO8601DateFormatter()
      let entry = "\(formatter.string(from: Date())) \(line)\n"
      if FileManager.default.fileExists(atPath: AppPaths.logUrl.path) {
        let handle = try FileHandle(forWritingTo: AppPaths.logUrl)
        try handle.seekToEnd()
        if let data = entry.data(using: .utf8) {
          try handle.write(contentsOf: data)
        }
        try handle.close()
      } else {
        try entry.write(to: AppPaths.logUrl, atomically: true, encoding: .utf8)
      }
    } catch {
      NSLog("LLWallPaper log failed: %@", error.localizedDescription)
    }
  }
}
