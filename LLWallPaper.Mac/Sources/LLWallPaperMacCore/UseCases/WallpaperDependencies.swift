import Foundation

@MainActor
public protocol CardCatalogProviding {
  var current: [CardItem] { get }
}

@MainActor
public protocol CacheStoring {
  func ensureLocal(card: CardItem, cacheMaxMb: Int, protectedUrls: Set<URL>) async -> URL?
}

@MainActor
public protocol DesktopWallpaperSetting {
  func setWallpaper(_ imageUrl: URL) throws
}

public protocol FavoritesReading {
  var favoriteKeys: Set<String> { get }
  var blockedKeys: Set<String> { get }
}

public protocol HistoryRecording {
  func append(_ entry: HistoryEntry, maxEntries: Int)
  func recentKeys(count: Int) -> Set<String>
  func recentLocalUrls(count: Int) -> Set<URL>
}
