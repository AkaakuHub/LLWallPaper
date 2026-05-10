import Foundation

public enum AppPaths {
  public static var root: URL {
    let baseUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[
      0]
    return baseUrl.appending(path: "LLWallPaper", directoryHint: .isDirectory)
  }

  public static var settingsUrl: URL {
    root.appending(path: "settings.json")
  }

  public static var favoritesUrl: URL {
    root.appending(path: "favorites.json")
  }

  public static var historyUrl: URL {
    root.appending(path: "history.json")
  }

  public static var logUrl: URL {
    root.appending(path: "logs/app.log")
  }

  public static var cacheRoot: URL {
    root.appending(path: "cache/images", directoryHint: .isDirectory)
  }

  public static func cacheUrl(for key: String) -> URL? {
    guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return nil
    }

    let safeId = key.map { character in
      character.isLetter || character.isNumber ? String(character) : "_"
    }.joined()
    return cacheRoot.appending(path: "card_\(safeId)_full.webp")
  }

  public static func ensureDirectories() throws {
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(
      at: logUrl.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try FileManager.default.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
  }
}
