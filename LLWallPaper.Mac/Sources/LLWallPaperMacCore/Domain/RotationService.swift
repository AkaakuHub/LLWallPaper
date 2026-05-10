import Foundation

public struct RotationService: Sendable {
  public init() {}

  public func pickNext(
    candidates: [CardItem],
    recentKeys: Set<String>,
    favoriteKeys: Set<String>,
    blockedKeys: Set<String>,
    settings: AppSettings
  ) -> CardItem? {
    var pool = candidates

    if settings.excludeBlocked {
      pool = pool.filter { !blockedKeys.contains($0.id) }
    }

    if settings.excludeThirdEvolution {
      pool = pool.filter { !$0.id.hasSuffix("2") }
    }

    if settings.excludeSrCards {
      pool = pool.filter { !CharacterMap.isSrCard($0.id) }
    }

    if !recentKeys.isEmpty {
      pool = pool.filter { !recentKeys.contains($0.id) }
    }

    if pool.isEmpty {
      return nil
    }

    if settings.preferFavorites {
      let favorites = pool.filter { favoriteKeys.contains($0.id) }
      if let favorite = favorites.randomElement() {
        return favorite
      }
    }

    return pool.randomElement()
  }
}
