# LLWallPaper

Windows desktop wallpaper rotator for LL card illustrations (WPF, .NET 10).

## Requirements
- Windows 11
- .NET SDK 10
- IDesktopWallpaper COM available on the OS

## Run
```
dotnet run --project .\LLWallPaper.App\
```

## Settings
The app stores settings under:
```
%LOCALAPPDATA%\MoshiMoshi\WallpaperApp\settings.json
```
Key fields:
- `backendBaseUrl` (e.g. `https://nijigasaki:5173`)
- `autoRotateEnabled`
- `rotateIntervalMinutes`
- `rotateOnAppStart`
- `recentExcludeCount`
- `preferFavorites`
- `excludeBlocked`
- `excludeThirdEvolution`
- `cacheMaxMb`

## Card API
The app fetches cards from:
```
{backendBaseUrl}/api/card-illustrations
```
Image URLs are constructed as:
```
{backendBaseUrl}/api/card-illustrations/image/{id}?type=full
{backendBaseUrl}/api/card-illustrations/image/{id}?type=half
```

## Cards tab
- Fetch runs the API call and updates the local list.
- Search filters the local list in real time.

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
dotnet tool run dotnet-format -- LLWallPaper.sln
```

Lint (Roslynator runs during build):
```
dotnet build LLWallPaper.sln
```

Sync lefthook (repo-local binary):
```
.\tools\lefthook\lefthook.exe install
```

## Notes
- Only `IDesktopWallpaper` is used (no fallback).
- If the COM class is unavailable, wallpaper changes are not supported on that system.

