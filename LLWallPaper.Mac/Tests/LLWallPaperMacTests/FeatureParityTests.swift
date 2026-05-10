import Foundation
import XCTest

@testable import LLWallPaperMacCore

final class FeatureParityTests: XCTestCase {
  func testDefaultSettingsMatchWindowsAppDefaults() {
    let settings = AppSettings()

    XCTAssertEqual(settings.backendBaseUrl, "http://127.0.0.1:3000")
    XCTAssertTrue(settings.autoRotateEnabled)
    XCTAssertEqual(settings.rotateIntervalMinutes, 15)
    XCTAssertTrue(settings.rotateOnAppStart)
    XCTAssertEqual(settings.recentExcludeCount, 30)
    XCTAssertTrue(settings.preferFavorites)
    XCTAssertTrue(settings.excludeBlocked)
    XCTAssertFalse(settings.excludeThirdEvolution)
    XCTAssertTrue(settings.excludeSrCards)
    XCTAssertFalse(settings.startWithMacOS)
    XCTAssertFalse(settings.startMinimized)
    XCTAssertEqual(settings.cacheMaxMb, 2048)
    XCTAssertEqual(settings.historyMaxEntries, 100)
  }

  @MainActor
  func testApplyCardDownloadsSetsWallpaperAndAppendsHistory() async throws {
    let card = try makeCard(id: "102111", name: "Card Name")
    let localUrl = try XCTUnwrap(URL(string: "file:///tmp/card_102111_full.webp"))
    let cacheStore = StubCacheStore(localUrl: localUrl)
    let wallpaperSetter = StubWallpaperSetter()
    let historyStore = StubHistoryStore()
    let useCase = WallpaperUseCase(
      catalogService: StubCatalog(cards: [card]),
      rotationService: RotationService(),
      cacheStore: cacheStore,
      desktopWallpaperAdapter: wallpaperSetter,
      favoritesStore: StubFavorites(),
      historyStore: historyStore,
      logger: AppLogger()
    )

    let result = await useCase.applyCard(card, settings: AppSettings(), reason: "manual")

    XCTAssertEqual(result, WallpaperResult(success: true, message: "Wallpaper updated."))
    XCTAssertEqual(cacheStore.requestedCardIds, ["102111"])
    XCTAssertEqual(wallpaperSetter.setUrls, [localUrl])
    XCTAssertEqual(historyStore.appendedEntries.map(\.key), ["102111"])
    XCTAssertEqual(historyStore.appendedEntries.map(\.cardName), ["Card Name"])
  }

  @MainActor
  func testApplyNextUsesSameRotationRulesAsWindowsApp() async throws {
    var settings = AppSettings()
    settings.excludeBlocked = true
    settings.excludeThirdEvolution = true
    settings.excludeSrCards = true
    settings.preferFavorites = true
    let favoriteCard = try makeCard(id: "102111", name: "Favorite")
    let blockedCard = try makeCard(id: "102122", name: "Blocked Third Evolution")
    let srCard = try makeCard(id: "102130", name: "SR")
    let wallpaperSetter = StubWallpaperSetter()
    let useCase = WallpaperUseCase(
      catalogService: StubCatalog(cards: [blockedCard, srCard, favoriteCard]),
      rotationService: RotationService(),
      cacheStore: StubCacheStore(localUrl: URL(fileURLWithPath: "/tmp/favorite.webp")),
      desktopWallpaperAdapter: wallpaperSetter,
      favoritesStore: StubFavorites(favoriteKeys: ["102111"], blockedKeys: ["102122"]),
      historyStore: StubHistoryStore(),
      logger: AppLogger()
    )

    let result = await useCase.applyNext(settings: settings)

    XCTAssertEqual(result, WallpaperResult(success: true, message: "Wallpaper updated."))
    XCTAssertEqual(wallpaperSetter.setUrls.map(\.lastPathComponent), ["favorite.webp"])
  }

  @MainActor
  func testApplyNextReportsNoEligibleCardsWhenFiltersRemoveEverything() async throws {
    var settings = AppSettings()
    settings.excludeBlocked = true
    let blockedCard = try makeCard(id: "102111", name: "Blocked")
    let useCase = WallpaperUseCase(
      catalogService: StubCatalog(cards: [blockedCard]),
      rotationService: RotationService(),
      cacheStore: StubCacheStore(localUrl: URL(fileURLWithPath: "/tmp/unused.webp")),
      desktopWallpaperAdapter: StubWallpaperSetter(),
      favoritesStore: StubFavorites(blockedKeys: ["102111"]),
      historyStore: StubHistoryStore(),
      logger: AppLogger()
    )

    let result = await useCase.applyNext(settings: settings)

    XCTAssertEqual(result, WallpaperResult(success: false, message: "No eligible cards."))
  }

  private func makeCard(id: String, name: String) throws -> CardItem {
    let imageUrl = try XCTUnwrap(URL(string: "http://127.0.0.1:3000/image/\(id).webp"))
    return CardItem(id: id, name: name, imageUrl: imageUrl, thumbnailUrl: nil)
  }
}

@MainActor
private final class StubCatalog: CardCatalogProviding {
  let current: [CardItem]

  init(cards: [CardItem]) {
    current = cards
  }
}

@MainActor
private final class StubCacheStore: CacheStoring {
  private let localUrl: URL?
  private(set) var requestedCardIds: [String] = []

  init(localUrl: URL?) {
    self.localUrl = localUrl
  }

  func ensureLocal(card: CardItem, cacheMaxMb: Int, protectedUrls: Set<URL>) async -> URL? {
    requestedCardIds.append(card.id)
    return localUrl
  }
}

@MainActor
private final class StubWallpaperSetter: DesktopWallpaperSetting {
  private(set) var setUrls: [URL] = []

  func setWallpaper(_ imageUrl: URL) throws {
    setUrls.append(imageUrl)
  }
}

private struct StubFavorites: FavoritesReading {
  let favoriteKeys: Set<String>
  let blockedKeys: Set<String>

  init(favoriteKeys: Set<String> = [], blockedKeys: Set<String> = []) {
    self.favoriteKeys = favoriteKeys
    self.blockedKeys = blockedKeys
  }
}

private final class StubHistoryStore: HistoryRecording {
  private(set) var appendedEntries: [HistoryEntry] = []

  func append(_ entry: HistoryEntry, maxEntries: Int) {
    appendedEntries.append(entry)
  }

  func recentKeys(count: Int) -> Set<String> {
    []
  }

  func recentLocalUrls(count: Int) -> Set<URL> {
    []
  }
}
