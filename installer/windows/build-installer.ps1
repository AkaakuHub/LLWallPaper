$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "../..")
$PublishDir = Join-Path $Root "publish"
$ProjectPath = Join-Path $Root "LLWallPaper.App/LLWallPaper.App.csproj"
$InstallerPath = Join-Path $PSScriptRoot "LLWallPaper.iss"
$IsccPath = Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6/ISCC.exe"
$Version = if ([string]::IsNullOrWhiteSpace($env:LLWALLPAPER_VERSION)) { "0.0.0-local" } else { $env:LLWALLPAPER_VERSION }

if (-not (Test-Path $IsccPath)) {
    throw "ISCC.exe was not found. Install Inno Setup 6 first."
}

dotnet publish $ProjectPath `
    -c Release `
    -r win-x64 `
    --self-contained true `
    -p:DebugType=none `
    -p:DebugSymbols=false `
    -p:Version=$Version `
    -o $PublishDir

Get-ChildItem -Path $PublishDir -Filter *.pdb -Recurse | Remove-Item -Force
Push-Location $PSScriptRoot
try {
    & $IsccPath "/DAppVersion=$Version" $InstallerPath
} finally {
    Pop-Location
}
