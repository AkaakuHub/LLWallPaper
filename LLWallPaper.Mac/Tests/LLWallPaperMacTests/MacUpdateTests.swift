import Foundation
import XCTest

@testable import LLWallPaperMacCore

final class MacUpdateTests: XCTestCase {
  func testAppVersionComparesSemanticVersionNumbers() throws {
    XCTAssertLessThan(try XCTUnwrap(AppVersion("1.3.3")), try XCTUnwrap(AppVersion("1.3.4")))
    XCTAssertLessThan(try XCTUnwrap(AppVersion("v1.3.9")), try XCTUnwrap(AppVersion("1.3.10")))
    XCTAssertEqual(try XCTUnwrap(AppVersion("1.3")), try XCTUnwrap(AppVersion("1.3.0")))
  }

  func testSelectUpdateUsesMacOSDmgAssetWithDigest() throws {
    let release = GitHubRelease(
      tagName: "v1.3.4",
      htmlUrl: "https://github.com/AkaakuHub/LLWallPaper/releases/tag/v1.3.4",
      assets: [
        GitHubReleaseAsset(
          name: "LLWallPaper-win-Setup.exe",
          browserDownloadUrl:
            "https://github.com/AkaakuHub/LLWallPaper/releases/download/v1.3.4/LLWallPaper-win-Setup.exe",
          digest: "sha256:windows"
        ),
        GitHubReleaseAsset(
          name: "LLWallPaper-macOS-1.3.4.dmg",
          browserDownloadUrl:
            "https://github.com/AkaakuHub/LLWallPaper/releases/download/v1.3.4/LLWallPaper-macOS-1.3.4.dmg",
          digest: "sha256:macos"
        ),
      ]
    )

    let update = try XCTUnwrap(
      MacUpdateSelection.selectUpdate(from: release, currentVersion: "1.3.3"))

    XCTAssertEqual(update.version, "1.3.4")
    XCTAssertEqual(update.assetName, "LLWallPaper-macOS-1.3.4.dmg")
    XCTAssertEqual(update.digest, "sha256:macos")
    XCTAssertEqual(
      update.downloadUrl.absoluteString,
      "https://github.com/AkaakuHub/LLWallPaper/releases/download/v1.3.4/LLWallPaper-macOS-1.3.4.dmg"
    )
  }

  func testSelectUpdateRejectsCurrentOrOlderVersion() {
    let release = GitHubRelease(
      tagName: "v1.3.3",
      htmlUrl: "https://github.com/AkaakuHub/LLWallPaper/releases/tag/v1.3.3",
      assets: [
        GitHubReleaseAsset(
          name: "LLWallPaper-macOS-1.3.3.dmg",
          browserDownloadUrl:
            "https://github.com/AkaakuHub/LLWallPaper/releases/download/v1.3.3/LLWallPaper-macOS-1.3.3.dmg",
          digest: "sha256:macos"
        )
      ]
    )

    XCTAssertNil(MacUpdateSelection.selectUpdate(from: release, currentVersion: "1.3.3"))
  }

  func testSelectUpdateRejectsAssetWithoutDigest() {
    let release = GitHubRelease(
      tagName: "v1.3.4",
      htmlUrl: "https://github.com/AkaakuHub/LLWallPaper/releases/tag/v1.3.4",
      assets: [
        GitHubReleaseAsset(
          name: "LLWallPaper-macOS-1.3.4.dmg",
          browserDownloadUrl:
            "https://github.com/AkaakuHub/LLWallPaper/releases/download/v1.3.4/LLWallPaper-macOS-1.3.4.dmg",
          digest: ""
        )
      ]
    )

    XCTAssertNil(MacUpdateSelection.selectUpdate(from: release, currentVersion: "1.3.3"))
  }

  func testInstallScriptMountsDmgCopiesAppAndRelaunches() {
    let script = MacUpdateInstallScript.make(
      dmgPath: "/tmp/LLWallPaper update.dmg",
      appBundlePath: "/Applications/LLWallPaper.app",
      processId: 1234
    )

    XCTAssertTrue(script.contains("while kill -0 1234"))
    XCTAssertTrue(
      script.contains("hdiutil attach -nobrowse -readonly '/tmp/LLWallPaper update.dmg'"))
    XCTAssertTrue(script.contains("source_app=\"$volume_path/LLWallPaper.app\""))
    XCTAssertTrue(script.contains("ditto \"$source_app\" '/Applications/LLWallPaper.app'"))
    XCTAssertTrue(script.contains("open '/Applications/LLWallPaper.app'"))
  }
}
