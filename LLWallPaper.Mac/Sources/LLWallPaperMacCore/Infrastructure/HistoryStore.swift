import Foundation

public final class HistoryStore: HistoryRecording {
  private let logger: AppLogger

  public init(logger: AppLogger) {
    self.logger = logger
  }

  public func append(_ entry: HistoryEntry, maxEntries: Int) {
    var state = loadState()
    state.basePath = resolvedBasePath(state.basePath)
    state.entries.append(entry)
    if maxEntries > 0 && state.entries.count > maxEntries {
      state.entries.removeFirst(state.entries.count - maxEntries)
    }
    saveState(state)
  }

  public func getState() -> HistoryState {
    loadState()
  }

  public func trimToMax(_ maxEntries: Int) {
    guard maxEntries > 0 else {
      return
    }

    var state = loadState()
    guard state.entries.count > maxEntries else {
      return
    }

    state.entries.removeFirst(state.entries.count - maxEntries)
    saveState(state)
  }

  public func recentKeys(count: Int) -> Set<String> {
    Set(recentEntries(count: count).map(\.key))
  }

  public func recentLocalUrls(count: Int) -> Set<URL> {
    Set(
      recentEntries(count: count)
        .compactMap { AppPaths.cacheUrl(for: $0.key) }
        .filter { FileManager.default.fileExists(atPath: $0.path) }
    )
  }

  private func recentEntries(count: Int) -> [HistoryEntry] {
    guard count > 0 else {
      return []
    }

    let entries = loadState().entries
    guard !entries.isEmpty else {
      return []
    }

    return Array(entries.suffix(count))
  }

  private func loadState() -> HistoryState {
    do {
      try AppPaths.ensureDirectories()
      guard FileManager.default.fileExists(atPath: AppPaths.historyUrl.path) else {
        let state = HistoryState(basePath: resolvedBasePath(""))
        saveState(state)
        return state
      }

      let data = try Data(contentsOf: AppPaths.historyUrl)
      var state = try JsonCoding.decoder.decode(HistoryState.self, from: data)
      state.basePath = resolvedBasePath(state.basePath)
      return state
    } catch {
      logger.error("Failed to read history entries.", error)
      return HistoryState(basePath: resolvedBasePath(""))
    }
  }

  private func saveState(_ state: HistoryState) {
    do {
      try AppPaths.ensureDirectories()
      var state = state
      state.basePath = resolvedBasePath(state.basePath)
      let data = try JsonCoding.encoder.encode(state)
      try data.write(to: AppPaths.historyUrl, options: .atomic)
    } catch {
      logger.error("Failed to save history entries.", error)
    }
  }

  private func resolvedBasePath(_ basePath: String) -> String {
    if !basePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return basePath
    }

    return AppPaths.cacheRoot.path
  }
}
