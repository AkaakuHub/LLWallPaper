import Foundation
import XCTest

@testable import LLWallPaperMacCore

final class FeatureParityTests: XCTestCase {
  func testDefaultSettingsMatchSharedFixture() throws {
    let fixture = try FeatureParityFixture.load()
    let settings = AppSettings()

    XCTAssertEqual(settings.backendBaseUrl, fixture.defaultSettings.backendBaseUrl)
    XCTAssertEqual(settings.autoRotateEnabled, fixture.defaultSettings.autoRotateEnabled)
    XCTAssertEqual(settings.rotateIntervalMinutes, fixture.defaultSettings.rotateIntervalMinutes)
    XCTAssertEqual(settings.rotateOnAppStart, fixture.defaultSettings.rotateOnAppStart)
    XCTAssertEqual(settings.recentExcludeCount, fixture.defaultSettings.recentExcludeCount)
    XCTAssertEqual(settings.preferFavorites, fixture.defaultSettings.preferFavorites)
    XCTAssertEqual(settings.excludeBlocked, fixture.defaultSettings.excludeBlocked)
    XCTAssertEqual(settings.excludeThirdEvolution, fixture.defaultSettings.excludeThirdEvolution)
    XCTAssertEqual(settings.excludeSrCards, fixture.defaultSettings.excludeSrCards)
    XCTAssertEqual(settings.startWithMacOS, fixture.defaultSettings.startWithOs)
    XCTAssertEqual(settings.startMinimized, fixture.defaultSettings.startMinimized)
    XCTAssertEqual(settings.cacheMaxMb, fixture.defaultSettings.cacheMaxMb)
    XCTAssertEqual(settings.historyMaxEntries, fixture.defaultSettings.historyMaxEntries)
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
  func testRotationMatchesSharedFixture() throws {
    let fixture = try FeatureParityFixture.load()
    let cards = fixture.cards.map(\.cardItem)

    for testCase in fixture.rotationCases {
      var settings = AppSettings()
      settings.preferFavorites = testCase.settings.preferFavorites
      settings.excludeBlocked = testCase.settings.excludeBlocked
      settings.excludeThirdEvolution = testCase.settings.excludeThirdEvolution
      settings.excludeSrCards = testCase.settings.excludeSrCards

      let card = RotationService().pickNext(
        candidates: cards,
        recentKeys: testCase.recentKeys,
        favoriteKeys: testCase.favoriteKeys,
        blockedKeys: testCase.blockedKeys,
        settings: settings
      )

      XCTAssertEqual(card?.id, testCase.expectedId, testCase.name)
    }
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
