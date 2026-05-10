import Foundation

@MainActor
public final class WallpaperUseCase {
  private let catalogService: CardCatalogProviding
  private let rotationService: RotationService
  private let cacheStore: CacheStoring
  private let desktopWallpaperAdapter: DesktopWallpaperSetting
  private let favoritesStore: FavoritesReading
  private let historyStore: HistoryRecording
  private let logger: AppLogger

  public var onWallpaperChanged: ((WallpaperChangedEvent) -> Void)?

  public init(
    catalogService: CardCatalogProviding,
    rotationService: RotationService,
    cacheStore: CacheStoring,
    desktopWallpaperAdapter: DesktopWallpaperSetting,
    favoritesStore: FavoritesReading,
    historyStore: HistoryRecording,
    logger: AppLogger
  ) {
    self.catalogService = catalogService
    self.rotationService = rotationService
    self.cacheStore = cacheStore
    self.desktopWallpaperAdapter = desktopWallpaperAdapter
    self.favoritesStore = favoritesStore
    self.historyStore = historyStore
    self.logger = logger
  }

  public func applyNext(settings: AppSettings) async -> WallpaperResult {
    let candidates = catalogService.current
    if candidates.isEmpty {
      return WallpaperResult(success: false, message: "No cards available.")
    }

    let card = rotationService.pickNext(
      candidates: candidates,
      recentKeys: historyStore.recentKeys(count: settings.recentExcludeCount),
      favoriteKeys: favoritesStore.favoriteKeys,
      blockedKeys: favoritesStore.blockedKeys,
      settings: settings
    )

    guard let card else {
      return WallpaperResult(success: false, message: "No eligible cards.")
    }

    return await applyCard(card, settings: settings, reason: "auto")
  }

  public func applyCard(_ card: CardItem, settings: AppSettings, reason: String) async
    -> WallpaperResult
  {
    let localUrl = await cacheStore.ensureLocal(
      card: card,
      cacheMaxMb: settings.cacheMaxMb,
      protectedUrls: historyStore.recentLocalUrls(count: settings.recentExcludeCount)
    )
    guard let localUrl else {
      return WallpaperResult(success: false, message: "Download failed.")
    }

    do {
      try desktopWallpaperAdapter.setWallpaper(localUrl)
    } catch {
      logger.error("SetWallpaper failed.", error)
      return WallpaperResult(success: false, message: "SetWallpaper failed.")
    }

    historyStore.append(
      HistoryEntry(at: Date(), key: card.id, cardName: card.name),
      maxEntries: settings.historyMaxEntries
    )
    onWallpaperChanged?(WallpaperChangedEvent(card: card, localUrl: localUrl, reason: reason))
    return WallpaperResult(success: true, message: "Wallpaper updated.")
  }
}
