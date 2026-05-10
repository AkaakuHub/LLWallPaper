import Foundation

public struct MacUpdateRelease: Equatable, Sendable {
  public let tagName: String
  public let version: String
  public let assetName: String
  public let downloadUrl: URL
  public let digest: String
  public let releasePageUrl: URL

  public init(
    tagName: String,
    version: String,
    assetName: String,
    downloadUrl: URL,
    digest: String,
    releasePageUrl: URL
  ) {
    self.tagName = tagName
    self.version = version
    self.assetName = assetName
    self.downloadUrl = downloadUrl
    self.digest = digest
    self.releasePageUrl = releasePageUrl
  }
}
