# LLWallPaper

Windows desktop wallpaper rotator for リンクラ card illustrations.
Now Compatible with llll-view.

## Requirements
- Windows 11
- .NET SDK 10

## Development
```
dotnet run --project .\LLWallPaper.App\
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
