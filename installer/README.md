# Installer

## Windows

Windows uses the Inno Setup definition in `installer/windows/LLWallPaper.iss`.

```
powershell -ExecutionPolicy Bypass -File .\installer\windows\build-installer.ps1
```

## macOS

macOS uses the native Swift app bundle script in `installer/macos/build-app.sh`.

```
./installer/macos/build-app.sh 1.0.0
```

The script creates `dist/LLWallPaper-macOS-1.0.0.dmg`.
