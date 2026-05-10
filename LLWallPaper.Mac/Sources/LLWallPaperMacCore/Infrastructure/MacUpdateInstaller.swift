import Foundation

public final class MacUpdateInstaller: Sendable {
  public init() {}

  public func installAndRelaunch(dmgUrl: URL, appBundleUrl: URL, processId: Int32 = getpid()) throws
  {
    let script = MacUpdateInstallScript.make(
      dmgPath: dmgUrl.path,
      appBundlePath: appBundleUrl.path,
      processId: processId
    )
    let scriptUrl = FileManager.default.temporaryDirectory
      .appending(path: "llwallpaper-update-\(UUID().uuidString).zsh")
    try script.write(to: scriptUrl, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o700],
      ofItemAtPath: scriptUrl.path
    )

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = [scriptUrl.path]
    try process.run()
  }
}

public enum MacUpdateInstallScript {
  public static func make(dmgPath: String, appBundlePath: String, processId: Int32) -> String {
    let quotedDmgPath = shellQuoted(dmgPath)
    let quotedAppBundlePath = shellQuoted(appBundlePath)
    return """
      #!/bin/zsh
      set -euo pipefail
      while kill -0 \(processId) 2>/dev/null; do
        sleep 0.2
      done
      mount_output="$(hdiutil attach -nobrowse -readonly \(quotedDmgPath) | tail -n 1)"
      volume_path="$(printf "%s\\n" "$mount_output" | awk -F "\\t" "{print \\$NF}")"
      if [[ -z "$volume_path" || ! -d "$volume_path" ]]; then
        exit 1
      fi
      trap 'hdiutil detach "$volume_path" >/dev/null 2>&1 || true' EXIT
      source_app="$volume_path/LLWallPaper.app"
      if [[ ! -d "$source_app" ]]; then
        exit 1
      fi
      ditto "$source_app" \(quotedAppBundlePath)
      hdiutil detach "$volume_path"
      trap - EXIT
      open \(quotedAppBundlePath)
      rm -f "$0"
      """
  }

  private static func shellQuoted(_ value: String) -> String {
    "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
  }
}
