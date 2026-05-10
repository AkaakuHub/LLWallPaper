# LLWallPaper

Windows and macOS desktop wallpaper rotator for リンクラ card illustrations.
Now Compatible with llll-view.

## Runtime Requirements
### Windows
- Windows 11
- .NET Desktop Runtime 10 x64

### macOS
- macOS 13 or later

## Development Requirements
### Windows
- .NET SDK 10

### macOS
- Xcode 26 or Swift 6.2 toolchain

## Windows Development
```
dotnet run --project .\LLWallPaper.App\
```

## macOS Development
```
cd LLWallPaper.Mac
swift run LLWallPaperMac
```

macOS tests:
```
cd LLWallPaper.Mac
swift test
```

macOS installer:
```
./installer/macos/build-app.sh 1.0.0
```

macOS install:
Download `LLWallPaper-macOS-x.y.z.dmg` from GitHub Releases, open it, and drag `LLWallPaper.app` to `Applications`.
If macOS says the app is damaged, run:
```
xattr -rc /Applications/LLWallPaper.app
```

Windows installer:
```
powershell -ExecutionPolicy Bypass -File .\installer\windows\build-installer.ps1
```
The Windows installer does not bundle .NET Desktop Runtime 10 x64. If the runtime is missing, the installer opens the Microsoft download page.

## Formatter / Linter / Hooks
Install lefthook with local tools:
```
powershell -ExecutionPolicy Bypass -File .\scripts\setup-hooks.ps1
```

One-time tool restore (local tools only):
```
dotnet tool restore
```

Format:
```
dotnet tool run csharpier -- format .
xcrun swift-format format --in-place --recursive --configuration .swift-format LLWallPaper.Mac/Sources LLWallPaper.Mac/Tests
```

Lint (Roslynator runs during build):
```
dotnet build LLWallPaper.sln
xcrun swift-format lint --strict --recursive --configuration .swift-format LLWallPaper.Mac/Sources LLWallPaper.Mac/Tests
```

Sync lefthook (repo-local binary):
```
.\tools\lefthook\lefthook.exe install
```
