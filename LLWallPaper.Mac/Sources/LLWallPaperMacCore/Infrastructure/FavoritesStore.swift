import Foundation

public final class FavoritesStore: FavoritesReading {
  private let logger: AppLogger
  private var state = Favorites()

  public init(logger: AppLogger) {
    self.logger = logger
  }

  public var favoriteKeys: Set<String> {
    Set(state.favoriteKeys)
  }

  public var blockedKeys: Set<String> {
    Set(state.blockedKeys)
  }

  public func load() {
    do {
      try AppPaths.ensureDirectories()
      guard FileManager.default.fileExists(atPath: AppPaths.favoritesUrl.path) else {
        save()
        return
      }

      let data = try Data(contentsOf: AppPaths.favoritesUrl)
      state = try JsonCoding.decoder.decode(Favorites.self, from: data)
    } catch {
      logger.error("Failed to load favorites, resetting.", error)
      state = Favorites()
    }
  }

  public func isFavorite(_ key: String) -> Bool {
    state.favoriteKeys.contains(key)
  }

  public func isBlocked(_ key: String) -> Bool {
    state.blockedKeys.contains(key)
  }

  public func toggleFavorite(_ key: String) {
    toggle(key: key, in: \.favoriteKeys)
    save()
  }

  public func toggleBlocked(_ key: String) {
    toggle(key: key, in: \.blockedKeys)
    save()
  }

  private func toggle(key: String, in keyPath: WritableKeyPath<Favorites, [String]>) {
    if let index = state[keyPath: keyPath].firstIndex(of: key) {
      state[keyPath: keyPath].remove(at: index)
    } else {
      state[keyPath: keyPath].append(key)
    }
  }

  private func save() {
    do {
      try AppPaths.ensureDirectories()
      let data = try JsonCoding.encoder.encode(state)
      try data.write(to: AppPaths.favoritesUrl, options: .atomic)
    } catch {
      logger.error("Failed to save favorites.", error)
    }
  }
}
