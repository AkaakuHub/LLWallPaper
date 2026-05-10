import Foundation

public final class SettingsStore {
  private let logger: AppLogger

  public init(logger: AppLogger) {
    self.logger = logger
  }

  public func load() -> AppSettings {
    do {
      try AppPaths.ensureDirectories()
      guard FileManager.default.fileExists(atPath: AppPaths.settingsUrl.path) else {
        let settings = AppSettings()
        save(settings)
        return settings
      }

      let data = try Data(contentsOf: AppPaths.settingsUrl)
      return try JsonCoding.decoder.decode(AppSettings.self, from: data)
    } catch {
      logger.error("Failed to load settings, using defaults.", error)
      return AppSettings()
    }
  }

  public func save(_ settings: AppSettings) {
    do {
      try AppPaths.ensureDirectories()
      let data = try JsonCoding.encoder.encode(settings)
      try data.write(to: AppPaths.settingsUrl, options: .atomic)
    } catch {
      logger.error("Failed to save settings.", error)
    }
  }
}
