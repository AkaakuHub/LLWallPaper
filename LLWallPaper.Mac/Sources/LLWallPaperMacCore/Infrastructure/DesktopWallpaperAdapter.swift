import AppKit
import Foundation

@MainActor
public final class DesktopWallpaperAdapter: DesktopWallpaperSetting {
  public init() {}

  public func setWallpaper(_ imageUrl: URL) throws {
    let screens = NSScreen.screens
    guard !screens.isEmpty else {
      throw DesktopWallpaperError.noScreen
    }

    for screen in screens {
      try NSWorkspace.shared.setDesktopImageURL(imageUrl, for: screen, options: [:])
    }
  }
}

public enum DesktopWallpaperError: LocalizedError, Equatable {
  case noScreen

  public var errorDescription: String? {
    switch self {
    case .noScreen:
      return "No display is available."
    }
  }
}
