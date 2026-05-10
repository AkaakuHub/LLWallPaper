import CryptoKit
import Foundation

public final class GitHubReleaseUpdateService: Sendable {
  private let latestReleaseUrl: URL
  private let session: URLSession
  private let logger: AppLogger

  public init(
    latestReleaseUrl: URL = URL(
      string: "https://api.github.com/repos/AkaakuHub/LLWallPaper/releases/latest")!,
    session: URLSession = .shared,
    logger: AppLogger
  ) {
    self.latestReleaseUrl = latestReleaseUrl
    self.session = session
    self.logger = logger
  }

  public func latestUpdate(currentVersion: String) async -> MacUpdateRelease? {
    do {
      var request = URLRequest(url: latestReleaseUrl)
      request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
      request.setValue("LLWallPaper", forHTTPHeaderField: "User-Agent")

      let (data, response) = try await session.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        return nil
      }

      let release = try JsonCoding.decoder.decode(GitHubRelease.self, from: data)
      return MacUpdateSelection.selectUpdate(from: release, currentVersion: currentVersion)
    } catch {
      logger.error("Update check failed.", error)
      return nil
    }
  }

  public func download(_ release: MacUpdateRelease) async throws -> URL {
    let (temporaryUrl, response) = try await session.download(from: release.downloadUrl)
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      throw MacUpdateError.downloadFailed
    }

    let destinationUrl = FileManager.default.temporaryDirectory
      .appending(path: release.assetName)
    if FileManager.default.fileExists(atPath: destinationUrl.path) {
      try FileManager.default.removeItem(at: destinationUrl)
    }
    try FileManager.default.moveItem(at: temporaryUrl, to: destinationUrl)
    try verifyDigest(release.digest, fileUrl: destinationUrl)
    return destinationUrl
  }

  private func verifyDigest(_ digest: String, fileUrl: URL) throws {
    let expectedDigest = String(digest.trimmingPrefix("sha256:")).lowercased()
    let fileHandle = try FileHandle(forReadingFrom: fileUrl)
    var hasher = SHA256()
    while let data = try fileHandle.read(upToCount: 1024 * 1024), !data.isEmpty {
      hasher.update(data: data)
    }
    try fileHandle.close()
    let actualDigest = hasher.finalize()
      .map { String(format: "%02x", $0) }
      .joined()
    guard actualDigest == expectedDigest else {
      throw MacUpdateError.digestMismatch
    }
  }
}

public enum MacUpdateError: Error {
  case downloadFailed
  case digestMismatch
}
