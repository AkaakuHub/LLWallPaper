import Foundation
import LLWallPaperMacCore
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
  @Published var settings: AppSettings
  @Published var statusText = "Ready"
  @Published var currentCardName = "-"
  @Published var currentCharacterName = "その他"
  @Published var currentCardId = "-"
  @Published var currentSource = "-"
  @Published var currentCard: CardItem?
  @Published var cardSearchText = ""
  @Published var cardStatusMessage = ""
  @Published var selectedCard: CardItem?
  @Published var cardSortColumn = CardSortColumn.id
  @Published var cardSortAscending = true
  @Published var historyItems: [HistoryEntry] = []
  @Published var historyBasePath = ""
  @Published var historyStatusMessage = "Ready"
  @Published var selectedHistoryEntry: HistoryEntry?

  private let logger = AppLogger()
  private let settingsStore: SettingsStore
  private let favoritesStore: FavoritesStore
  private let historyStore: HistoryStore
  private let catalogService: CardCatalogService
  private let wallpaperUseCase: WallpaperUseCase
  private let startupService = StartupService()
  private let imageClipboardService = ImageClipboardService()
  private let cardDetailLinkService: CardDetailLinkService
  private var hasInitialized = false
  private var schedulerTask: Task<Void, Never>?

  init() {
    let logger = AppLogger()
    let settingsStore = SettingsStore(logger: logger)
    let favoritesStore = FavoritesStore(logger: logger)
    let historyStore = HistoryStore(logger: logger)
    let backendApiClient = BackendApiClient(logger: logger)
    let catalogService = CardCatalogService(backendApiClient: backendApiClient)
    let cacheStore = CacheStore(logger: logger)
    let wallpaperUseCase = WallpaperUseCase(
      catalogService: catalogService,
      rotationService: RotationService(),
      cacheStore: cacheStore,
      desktopWallpaperAdapter: DesktopWallpaperAdapter(),
      favoritesStore: favoritesStore,
      historyStore: historyStore,
      logger: logger
    )

    self.settings = settingsStore.load()
    self.settingsStore = settingsStore
    self.favoritesStore = favoritesStore
    self.historyStore = historyStore
    self.catalogService = catalogService
    self.wallpaperUseCase = wallpaperUseCase
    self.cardDetailLinkService = CardDetailLinkService(logger: logger)

    wallpaperUseCase.onWallpaperChanged = { [weak self] event in
      self?.handleWallpaperChanged(event)
    }
  }

  var filteredCards: [CardItem] {
    let cards = catalogService.search(cardSearchText, settings: settings)
    return cards.sorted { left, right in
      let result: ComparisonResult =
        switch cardSortColumn {
        case .id:
          left.id.localizedStandardCompare(right.id)
        case .name:
          left.name.localizedStandardCompare(right.name)
        case .characterName:
          CharacterMap.name(for: left.id).localizedStandardCompare(CharacterMap.name(for: right.id))
        case .favorite:
          String(isFavorite(left.id)).localizedStandardCompare(String(isFavorite(right.id)))
        case .blocked:
          String(isBlocked(left.id)).localizedStandardCompare(String(isBlocked(right.id)))
        }
      return cardSortAscending ? result == .orderedAscending : result == .orderedDescending
    }
  }

  var isAutoEnabled: Bool {
    settings.autoRotateEnabled
  }

  var currentIsFavorite: Bool {
    guard let currentCard else {
      return false
    }

    return favoritesStore.isFavorite(currentCard.id)
  }

  var currentIsBlocked: Bool {
    guard let currentCard else {
      return false
    }

    return favoritesStore.isBlocked(currentCard.id)
  }

  var selectedHistoryImageUrl: URL? {
    guard let selectedHistoryEntry else {
      return nil
    }

    return AppPaths.cacheUrl(for: selectedHistoryEntry.key)
  }

  var hasSelectedHistoryImage: Bool {
    guard let selectedHistoryImageUrl else {
      return false
    }

    return FileManager.default.fileExists(atPath: selectedHistoryImageUrl.path)
  }

  func initialize() async {
    if hasInitialized {
      return
    }
    hasInitialized = true

    favoritesStore.load()
    await fetchCardsWithRetry(initialDelaySeconds: 0)
    refreshHistory()

    if settings.rotateOnAppStart {
      await applyNext()
    }

    if settings.autoRotateEnabled {
      startScheduler()
    }
  }

  func fetchCardsWithRetry(initialDelaySeconds: UInt64 = 0) async {
    if initialDelaySeconds > 0 {
      cardStatusMessage = "Waiting for backend..."
      try? await Task.sleep(for: .seconds(initialDelaySeconds))
    }

    for attempt in 1...5 {
      do {
        try await catalogService.refresh(baseUrl: settings.backendBaseUrl)
        cardStatusMessage = "Loaded \(filteredCards.count) cards."
        return
      } catch {
        if attempt == 5 {
          cardStatusMessage = "Failed to connect after 5 attempts."
          return
        }

        cardStatusMessage = "Fetch failed. Retrying (\(attempt)/5)..."
        try? await Task.sleep(for: .seconds(30))
      }
    }
  }

  func applyNext() async {
    statusText = "Applying next wallpaper..."
    let result = await wallpaperUseCase.applyNext(settings: settings)
    statusText = result.message
  }

  func applySelectedCard() async {
    guard let selectedCard else {
      return
    }

    let result = await wallpaperUseCase.applyCard(
      selectedCard, settings: settings, reason: "manual")
    cardStatusMessage = result.message
  }

  func toggleAuto() {
    settings.autoRotateEnabled.toggle()
    settingsStore.save(settings)
    if settings.autoRotateEnabled {
      startScheduler()
      statusText = "Auto-rotate enabled."
    } else {
      stopScheduler()
      statusText = "Auto-rotate paused."
    }
  }

  func toggleCurrentFavorite() {
    guard let currentCard else {
      return
    }

    favoritesStore.toggleFavorite(currentCard.id)
    statusText = currentIsFavorite ? "Marked as favorite." : "Removed from favorites."
    objectWillChange.send()
  }

  func toggleCurrentBlocked() {
    guard let currentCard else {
      return
    }

    favoritesStore.toggleBlocked(currentCard.id)
    statusText = currentIsBlocked ? "Marked as blocked." : "Removed from blocked."
    objectWillChange.send()
  }

  func toggleSelectedFavorite() {
    guard let selectedCard else {
      return
    }

    favoritesStore.toggleFavorite(selectedCard.id)
    objectWillChange.send()
  }

  func toggleSelectedBlocked() {
    guard let selectedCard else {
      return
    }

    favoritesStore.toggleBlocked(selectedCard.id)
    objectWillChange.send()
  }

  func isFavorite(_ key: String) -> Bool {
    favoritesStore.isFavorite(key)
  }

  func isBlocked(_ key: String) -> Bool {
    favoritesStore.isBlocked(key)
  }

  func sortCards(by column: CardSortColumn) {
    if cardSortColumn == column {
      cardSortAscending.toggle()
    } else {
      cardSortColumn = column
      cardSortAscending = true
    }
  }

  func saveSettings() {
    settingsStore.save(settings)
    historyStore.trimToMax(settings.historyMaxEntries)
    do {
      try startupService.setEnabled(settings.startWithMacOS)
      statusText = "Settings saved."
    } catch {
      logger.error("Failed to update login item.", error)
      statusText = "Settings saved. Login item update failed."
    }

    refreshHistory()
    if settings.autoRotateEnabled {
      startScheduler()
    } else {
      stopScheduler()
    }
  }

  func refreshHistory() {
    let state = historyStore.getState()
    historyBasePath = state.basePath
    historyItems = state.entries.sorted { $0.at > $1.at }
    selectedHistoryEntry = historyItems.first
    historyStatusMessage = "Loaded \(historyItems.count) entries."
  }

  func applySelectedHistoryEntry() async {
    guard let selectedHistoryEntry else {
      historyStatusMessage = "No card selected."
      return
    }

    guard let card = catalogService.current.first(where: { $0.id == selectedHistoryEntry.key })
    else {
      historyStatusMessage = "Card not found in catalog. Please fetch cards first."
      return
    }

    let result = await wallpaperUseCase.applyCard(card, settings: settings, reason: "history")
    historyStatusMessage = result.message
  }

  func copySelectedHistoryImage() {
    guard let selectedHistoryImageUrl, hasSelectedHistoryImage else {
      historyStatusMessage = "No image to copy."
      return
    }

    historyStatusMessage =
      imageClipboardService.copyImage(at: selectedHistoryImageUrl)
      ? "Image copied to clipboard."
      : "Failed to copy image."
  }

  func openSelectedHistoryDetail() {
    guard let selectedHistoryEntry else {
      historyStatusMessage = "No card selected."
      return
    }

    if let errorMessage = cardDetailLinkService.open(
      key: selectedHistoryEntry.key,
      baseUrl: settings.backendBaseUrl
    ) {
      historyStatusMessage = errorMessage
    } else {
      historyStatusMessage = "Opened card detail."
    }
  }

  func toggleSelectedHistoryFavorite() {
    guard let selectedHistoryEntry else {
      historyStatusMessage = "No card selected."
      return
    }

    favoritesStore.toggleFavorite(selectedHistoryEntry.key)
    historyStatusMessage =
      favoritesStore.isFavorite(selectedHistoryEntry.key)
      ? "Marked as favorite."
      : "Removed from favorites."
    objectWillChange.send()
  }

  func toggleSelectedHistoryBlocked() {
    guard let selectedHistoryEntry else {
      historyStatusMessage = "No card selected."
      return
    }

    favoritesStore.toggleBlocked(selectedHistoryEntry.key)
    historyStatusMessage =
      favoritesStore.isBlocked(selectedHistoryEntry.key)
      ? "Marked as blocked."
      : "Removed from blocked."
    objectWillChange.send()
  }

  private func handleWallpaperChanged(_ event: WallpaperChangedEvent) {
    currentCard = event.card
    currentCardName = event.card.name
    currentCharacterName = CharacterMap.name(for: event.card.id)
    currentCardId = event.card.id
    currentSource = event.reason
    statusText = "Wallpaper updated."
    refreshHistory()
  }

  private func startScheduler() {
    stopScheduler()
    schedulerTask = Task { [weak self] in
      while !Task.isCancelled {
        guard let self else {
          return
        }

        let interval = max(1, self.settings.rotateIntervalMinutes)
        try? await Task.sleep(for: .seconds(interval * 60))
        if !Task.isCancelled, self.settings.autoRotateEnabled {
          await self.applyNext()
        }
      }
    }
  }

  private func stopScheduler() {
    schedulerTask?.cancel()
    schedulerTask = nil
  }
}

enum CardSortColumn {
  case id
  case name
  case characterName
  case favorite
  case blocked
}
