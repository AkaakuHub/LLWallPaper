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

assert_contains ".github/workflows/release.yml" "--self-contained false"
assert_not_contains ".github/workflows/release.yml" "--self-contained true"
assert_contains "installer/windows/build-installer.ps1" "--self-contained false"
assert_contains "installer/windows/build-installer.ps1" "Remove-Item -Path \$PublishDir -Recurse -Force"
assert_not_contains "installer/windows/build-installer.ps1" "--self-contained true"
assert_contains "installer/windows/LLWallPaper.iss" "Microsoft.WindowsDesktop.App"
assert_contains "installer/windows/LLWallPaper.iss" ".NET Desktop Runtime 10 x64"
assert_not_contains "installer/windows/LLWallPaper.iss" "InstalledVersions\\x86\\sharedfx"
assert_contains ".github/workflows/release.yml" "dist/LLWallPaper-macOS-"
assert_contains ".github/workflows/release.yml" "gh release upload"
assert_contains "installer/macos/build-app.sh" "ln -s /Applications"
assert_contains "installer/README.md" "ad-hoc signed"
assert_contains "README.md" "The Windows installer does not bundle .NET Desktop Runtime 10 x64."
assert_contains "installer/README.md" "The installer does not bundle .NET Desktop Runtime 10 x64."
