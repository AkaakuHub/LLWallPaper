import AppKit
import Foundation

@MainActor
public final class CardDetailLinkService {
  private let logger: AppLogger

  public init(logger: AppLogger) {
    self.logger = logger
  }

  public func open(key: String, baseUrl: String) -> String? {
    guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return "No card selected."
    }

    guard let baseUrl = URL(string: baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)) else {
      return "Base URL is invalid."
    }

    let detailUrl = baseUrl.appending(path: "card/\(key)")
    if NSWorkspace.shared.open(detailUrl) {
      return nil
    }

    logger.error("Failed to open card detail URL.")
    return "Failed to open browser."
  }
}
