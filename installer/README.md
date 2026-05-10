# Installer

## Windows

Windows uses the Inno Setup definition in `installer/windows/LLWallPaper.iss`.
The installer does not bundle .NET Desktop Runtime 10 x64. It checks the shared runtime and opens the Microsoft download page when the runtime is missing.

```
powershell -ExecutionPolicy Bypass -File .\installer\windows\build-installer.ps1
```

## macOS

macOS uses the native Swift app bundle script in `installer/macos/build-app.sh`.
When `MACOS_CODESIGN_IDENTITY` is unset, the app bundle is ad-hoc signed. This repository creates a DMG and does not notarize it.

```
./installer/macos/build-app.sh 1.0.0
```

The script creates `dist/LLWallPaper-macOS-1.0.0.dmg`.
