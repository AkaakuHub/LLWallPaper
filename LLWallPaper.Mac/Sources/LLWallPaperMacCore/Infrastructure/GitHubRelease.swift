import Foundation

public struct GitHubRelease: Decodable, Equatable, Sendable {
  public let tagName: String
  public let htmlUrl: String
  public let assets: [GitHubReleaseAsset]

  public init(tagName: String, htmlUrl: String, assets: [GitHubReleaseAsset]) {
    self.tagName = tagName
    self.htmlUrl = htmlUrl
    self.assets = assets
  }

  private enum CodingKeys: String, CodingKey {
    case tagName = "tag_name"
    case htmlUrl = "html_url"
    case assets
  }
}

public struct GitHubReleaseAsset: Decodable, Equatable, Sendable {
  public let name: String
  public let browserDownloadUrl: String
  public let digest: String

  public init(name: String, browserDownloadUrl: String, digest: String) {
    self.name = name
    self.browserDownloadUrl = browserDownloadUrl
    self.digest = digest
  }

  private enum CodingKeys: String, CodingKey {
    case name
    case browserDownloadUrl = "browser_download_url"
    case digest
  }
}
