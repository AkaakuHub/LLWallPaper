import AppKit
import Foundation

@MainActor
public final class ImageClipboardService {
  public init() {}

  public func copyImage(at url: URL) -> Bool {
    guard let image = NSImage(contentsOf: url) else {
      return false
    }

    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    return pasteboard.writeObjects([image])
  }
}
