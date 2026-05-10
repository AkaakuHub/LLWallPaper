#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

assert_contains() {
  local path="$1"
  local expected="$2"

  if ! grep -Fq -- "$expected" "$ROOT_DIR/$path"; then
    echo "$path does not contain required text: $expected" >&2
    exit 1
  fi
}

assert_not_contains() {
  local path="$1"
  local unexpected="$2"

  if grep -Fq -- "$unexpected" "$ROOT_DIR/$path"; then
    echo "$path contains forbidden text: $unexpected" >&2
    exit 1
  fi
}

assert_file_exists() {
  local path="$1"

  if [[ ! -f "$ROOT_DIR/$path" ]]; then
    echo "$path does not exist" >&2
    exit 1
  fi
}

assert_contains ".github/workflows/release.yml" "--self-contained false"
assert_not_contains ".github/workflows/release.yml" "--self-contained true"
assert_contains ".github/workflows/release.yml" "matrix:"
assert_contains ".github/workflows/release.yml" "platform: windows"
assert_contains ".github/workflows/release.yml" "platform: macos"
assert_contains "installer/windows/build-installer.ps1" "--self-contained false"
assert_contains "installer/windows/build-installer.ps1" "Remove-Item -Path \$PublishDir -Recurse -Force"
assert_not_contains "installer/windows/build-installer.ps1" "--self-contained true"
assert_contains "installer/windows/LLWallPaper.iss" "Microsoft.WindowsDesktop.App"
assert_contains "installer/windows/LLWallPaper.iss" ".NET Desktop Runtime 10 x64"
assert_not_contains "installer/windows/LLWallPaper.iss" "InstalledVersions\\x86\\sharedfx"
assert_contains ".github/workflows/release.yml" "dist/LLWallPaper-macOS-"
assert_contains ".github/workflows/release.yml" "gh release upload"
assert_contains ".github/workflows/release.yml" "Wait for GitHub Release"
assert_contains "installer/macos/build-app.sh" "ln -s /Applications"
assert_contains "installer/macos/build-app.sh" "LLWallPaper.icns"
assert_contains "installer/macos/build-app.sh" "LLWallPaperMenuBar.png"
assert_contains "installer/macos/build-app.sh" "LSUIElement"
assert_contains "LLWallPaper.Mac/Package.swift" ".process(\"Resources\")"
assert_contains "LLWallPaper.Mac/Sources/LLWallPaperMac/App/LLWallPaperMacApp.swift" "MenuBarExtra"
assert_contains "LLWallPaper.Mac/Sources/LLWallPaperMac/App/LLWallPaperMacApp.swift" "checkForUpdatesOnStartup"
assert_contains "LLWallPaper.Mac/Sources/LLWallPaperMac/App/MenuBarIcon.swift" "LLWallPaperMenuBar"
assert_contains "LLWallPaper.Mac/Sources/LLWallPaperMac/App/StartupUpdateController.swift" "Update available. Install now?"
assert_contains "LLWallPaper.Mac/Sources/LLWallPaperMacCore/Infrastructure/GitHubReleaseUpdateService.swift" "https://api.github.com/repos/AkaakuHub/LLWallPaper/releases/latest"
assert_contains "LLWallPaper.Mac/Sources/LLWallPaperMacCore/Infrastructure/GitHubReleaseUpdateService.swift" "verifyDigest"
assert_contains "LLWallPaper.Mac/Sources/LLWallPaperMacCore/Infrastructure/MacUpdateInstaller.swift" "ditto"
assert_contains "LLWallPaper.Mac/Sources/LLWallPaperMac/App/AppDelegate.swift" "applicationShouldTerminateAfterLastWindowClosed"
assert_file_exists "LLWallPaper.Mac/Sources/LLWallPaperMac/Resources/LLWallPaperMenuBar.png"
assert_contains "installer/README.md" "ad-hoc signed"
assert_contains "README.md" "The Windows installer does not bundle .NET Desktop Runtime 10 x64."
assert_contains "installer/README.md" "The installer does not bundle .NET Desktop Runtime 10 x64."
