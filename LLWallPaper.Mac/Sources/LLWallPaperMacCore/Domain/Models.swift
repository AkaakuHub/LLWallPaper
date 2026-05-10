import Foundation

public struct CardItem: Codable, Hashable, Identifiable, Sendable {
  public let id: String
  public let name: String
  public let imageUrl: URL
  public let thumbnailUrl: URL?

  public init(id: String, name: String, imageUrl: URL, thumbnailUrl: URL?) {
    self.id = id
    self.name = name
    self.imageUrl = imageUrl
    self.thumbnailUrl = thumbnailUrl
  }
}

public struct AppSettings: Codable, Equatable, Sendable {
  public var backendBaseUrl = "http://127.0.0.1:3000"
  public var autoRotateEnabled = true
  public var rotateIntervalMinutes = 15
  public var rotateOnAppStart = true
  public var recentExcludeCount = 30
  public var preferFavorites = true
  public var excludeBlocked = true
  public var excludeThirdEvolution = false
  public var excludeSrCards = true
  public var startWithMacOS = false
  public var startMinimized = false
  public var cacheMaxMb = 2048
  public var historyMaxEntries = 100

  public init() {}
}

public struct Favorites: Codable, Equatable, Sendable {
  public var favoriteKeys: [String] = []
  public var blockedKeys: [String] = []

  public init(favoriteKeys: [String] = [], blockedKeys: [String] = []) {
    self.favoriteKeys = favoriteKeys
    self.blockedKeys = blockedKeys
  }
}

public struct HistoryEntry: Codable, Hashable, Identifiable, Sendable {
  public let at: Date
  public let key: String
  public let cardName: String

  public init(at: Date, key: String, cardName: String) {
    self.at = at
    self.key = key
    self.cardName = cardName
  }

  public var id: String {
    "\(at.timeIntervalSince1970)-\(key)-\(cardName)"
  }

  public var characterName: String {
    CharacterMap.name(for: key)
  }
}

public struct HistoryState: Codable, Equatable, Sendable {
  public var basePath = ""
  public var entries: [HistoryEntry] = []

  public init(basePath: String = "", entries: [HistoryEntry] = []) {
    self.basePath = basePath
    self.entries = entries
  }
}

public struct WallpaperResult: Equatable, Sendable {
  public let success: Bool
  public let message: String

  public init(success: Bool, message: String) {
    self.success = success
    self.message = message
  }
}

public struct WallpaperChangedEvent: Equatable, Sendable {
  public let card: CardItem
  public let localUrl: URL
  public let reason: String

  public init(card: CardItem, localUrl: URL, reason: String) {
    self.card = card
    self.localUrl = localUrl
    self.reason = reason
  }
}
