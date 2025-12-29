[Setup]
AppId={{E6D5046F-0E08-4B9B-9C7E-34D6B3B97E52}
AppName=LLWallPaper
AppVersion=1.0.0
AppPublisher=AkaakuHub
DefaultDirName={autopf}\LLWallPaper
DefaultGroupName=LLWallPaper
DisableProgramGroupPage=yes
OutputBaseFilename=LLWallPaper-Installer
OutputDir=Output
Compression=lzma
SolidCompression=yes
SetupIconFile=icon\llwallpaper.ico
UninstallDisplayIcon={app}\LLWallPaper.App.exe

[Files]
Source: "..\LLWallPaper.App\bin\Release\net10.0-windows\win-x64\publish\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\LLWallPaper"; Filename: "{app}\LLWallPaper.App.exe"
Name: "{autodesktop}\LLWallPaper"; Filename: "{app}\LLWallPaper.App.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons"; Flags: unchecked

[Run]
Filename: "{app}\LLWallPaper.App.exe"; Description: "Launch LLWallPaper"; Flags: nowait postinstall skipifsilent

[Code]
function IsDesktopRuntime10Installed(): Boolean;
var
  Version: string;
begin
  Result := RegQueryStringValue(
    HKLM64,
    'SOFTWARE\dotnet\Setup\InstalledVersions\x64\sharedfx\Microsoft.WindowsDesktop.App',
    'Version',
    Version
  );
end;

function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  if IsDesktopRuntime10Installed() then
  begin
    Result := True;
  end
  else
  begin
    MsgBox(
      '.NET Desktop Runtime 10 is required to run LLWallPaper.'#13#10 +
      'Please install it and then run this installer again.',
      mbInformation,
      MB_OK
    );
    ShellExec('open',
      'https://dotnet.microsoft.com/en-us/download/dotnet/10.0',
      '', '', SW_SHOWNORMAL, ewNoWait, ResultCode);
    Result := False;
  end;
end;
