# LLWallPaper

Windows and macOS desktop wallpaper rotator for リンクラ card illustrations.
Now Compatible with llll-view.

## Requirements
### Windows
- Windows 11
- .NET SDK 10

### macOS
- macOS 13 or later
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

Windows installer:
```
powershell -ExecutionPolicy Bypass -File .\installer\windows\build-installer.ps1
```

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
