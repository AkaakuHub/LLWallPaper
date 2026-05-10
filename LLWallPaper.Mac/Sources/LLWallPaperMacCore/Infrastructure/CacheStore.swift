import Foundation

@MainActor
public final class CacheStore: CacheStoring {
  private let session: URLSession
  private let logger: AppLogger

  public init(session: URLSession = .shared, logger: AppLogger) {
    self.session = session
    self.logger = logger
  }

  public func ensureLocal(card: CardItem, cacheMaxMb: Int, protectedUrls: Set<URL>) async -> URL? {
    do {
      try AppPaths.ensureDirectories()
      guard let localUrl = AppPaths.cacheUrl(for: card.id) else {
        logger.error("Cache path could not be generated for empty card id.")
        return nil
      }

      if FileManager.default.fileExists(atPath: localUrl.path) {
        return localUrl
      }

      let (temporaryUrl, response) = try await session.download(from: card.imageUrl)
      guard let httpResponse = response as? HTTPURLResponse,
        (200..<300).contains(httpResponse.statusCode)
      else {
        logger.error("Download failed for \(card.id).")
        return nil
      }

      if FileManager.default.fileExists(atPath: localUrl.path) {
        try FileManager.default.removeItem(at: localUrl)
      }
      try FileManager.default.moveItem(at: temporaryUrl, to: localUrl)
      trimCache(maxMb: cacheMaxMb, protectedUrls: protectedUrls.union([localUrl]))
      return localUrl
    } catch {
      logger.error("Download failed for \(card.id).", error)
      return nil
    }
  }

  private func trimCache(maxMb: Int, protectedUrls: Set<URL>) {
    let maxBytes = Int64(maxMb) * 1024 * 1024
    guard maxBytes > 0 else {
      return
    }

    do {
      let urls = try FileManager.default.contentsOfDirectory(
        at: AppPaths.cacheRoot,
        includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
      )
      var totalBytes = try urls.reduce(Int64(0)) { total, url in
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        return total + Int64(values.fileSize ?? 0)
      }

      let removableUrls =
        try urls
        .filter { !protectedUrls.contains($0) }
        .sorted {
          let left =
            try $0.resourceValues(forKeys: [.contentModificationDateKey])
            .contentModificationDate ?? .distantPast
          let right =
            try $1.resourceValues(forKeys: [.contentModificationDateKey])
            .contentModificationDate ?? .distantPast
          return left < right
        }

      for url in removableUrls {
        guard totalBytes > maxBytes else {
          return
        }

        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        totalBytes -= Int64(values.fileSize ?? 0)
        try FileManager.default.removeItem(at: url)
      }
    } catch {
      logger.error("Failed to trim cache.", error)
    }
  }
}
