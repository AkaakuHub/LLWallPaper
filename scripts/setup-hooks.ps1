param(
    [string]$InstallDir = "$PSScriptRoot\..\tools\lefthook"
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

$apiUrl = 'https://api.github.com/repos/evilmartians/lefthook/releases/latest'
$release = Invoke-RestMethod -Uri $apiUrl -Headers @{ 'User-Agent' = 'LLWallPaper' }
$asset = $release.assets | Where-Object {
    $_.name -match '(?i)windows' -and
    $_.name -match '(?i)x86_64' -and
    $_.name -match '(?i)\.exe$'
} | Select-Object -First 1
if (-not $asset) {
    Write-Host "Available assets:" -ForegroundColor Yellow
    $release.assets | ForEach-Object { Write-Host " - $($_.name)" }
    throw 'Could not find lefthook Windows asset.'
}

if (-not $asset) {
    Write-Host "Available assets:" -ForegroundColor Yellow
    $release.assets | ForEach-Object { Write-Host " - $($_.name)" }
    throw 'Could not find lefthook Windows x86_64 .exe asset.'
}

$target = Join-Path $InstallDir 'lefthook.exe'
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $target

& $target install
Write-Host "lefthook installed at $target"
