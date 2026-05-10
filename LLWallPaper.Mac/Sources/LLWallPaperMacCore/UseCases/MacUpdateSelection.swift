import Foundation

public enum MacUpdateSelection {
  public static func selectUpdate(
    from release: GitHubRelease,
    currentVersion: String
  ) -> MacUpdateRelease? {
    guard
      let latestVersion = AppVersion(release.tagName),
      let currentVersion = AppVersion(currentVersion),
      latestVersion > currentVersion
    else {
      return nil
    }

    let version = String(release.tagName.trimmingPrefix("v"))
    let assetName = "LLWallPaper-macOS-\(version).dmg"
    guard
      let asset = release.assets.first(where: { $0.name == assetName }),
      asset.digest.hasPrefix("sha256:"),
      let downloadUrl = URL(string: asset.browserDownloadUrl),
      let releasePageUrl = URL(string: release.htmlUrl)
    else {
      return nil
    }

    return MacUpdateRelease(
      tagName: release.tagName,
      version: version,
      assetName: asset.name,
      downloadUrl: downloadUrl,
      digest: asset.digest,
      releasePageUrl: releasePageUrl
    )
  }
}
