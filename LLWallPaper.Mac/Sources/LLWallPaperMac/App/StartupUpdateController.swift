import AppKit
import Foundation
import LLWallPaperMacCore

@MainActor
final class StartupUpdateController {
  private let logger = AppLogger()
  private let updateService: GitHubReleaseUpdateService
  private let installer = MacUpdateInstaller()

  init() {
    updateService = GitHubReleaseUpdateService(logger: logger)
  }

  func checkForUpdatesOnStartup() async {
    guard
      let currentVersion = Bundle.main.object(
        forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
      Bundle.main.bundleURL.pathExtension == "app"
    else {
      return
    }

    guard let release = await updateService.latestUpdate(currentVersion: currentVersion) else {
      return
    }

    let result = showUpdatePrompt(release: release)
    guard result == .alertFirstButtonReturn else {
      return
    }

    do {
      let dmgUrl = try await updateService.download(release)
      try installer.installAndRelaunch(
        dmgUrl: dmgUrl,
        appBundleUrl: Bundle.main.bundleURL
      )
      NSApplication.shared.terminate(nil)
    } catch {
      logger.error("Update install failed.", error)
      showInstallError(release: release)
    }
  }

  private func showUpdatePrompt(release: MacUpdateRelease) -> NSApplication.ModalResponse {
    NSApplication.shared.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.messageText = "Update available. Install now?"
    alert.informativeText = "LLWallPaper \(release.version) is available."
    alert.addButton(withTitle: "Install")
    alert.addButton(withTitle: "Not Now")
    alert.alertStyle = .informational
    return alert.runModal()
  }

  private func showInstallError(release: MacUpdateRelease) {
    NSApplication.shared.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.messageText = "Update failed."
    alert.informativeText =
      "LLWallPaper \(release.version) could not be installed automatically."
    alert.addButton(withTitle: "OK")
    alert.alertStyle = .warning
    alert.runModal()
  }
}
