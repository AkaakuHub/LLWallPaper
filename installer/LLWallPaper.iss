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
function GetVersionPart(const Version: string; Index: Integer): Integer;
var
  I: Integer;
  PartIndex: Integer;
  Num: string;
begin
  PartIndex := 1;
  Num := '';
  for I := 1 to Length(Version) do
  begin
    if Version[I] = '.' then
    begin
      if PartIndex = Index then
        Break;
      PartIndex := PartIndex + 1;
      Num := '';
      Continue;
    end;
    if PartIndex = Index then
    begin
      if (Version[I] >= '0') and (Version[I] <= '9') then
        Num := Num + Version[I];
    end;
  end;
  Result := StrToIntDef(Num, 0);
end;

function CompareVersion(const A, B: string): Integer;
var
  I: Integer;
  PartA: Integer;
  PartB: Integer;
begin
  Result := 0;
  for I := 1 to 4 do
  begin
    PartA := GetVersionPart(A, I);
    PartB := GetVersionPart(B, I);
    if PartA < PartB then
    begin
      Result := -1;
      Exit;
    end;
    if PartA > PartB then
    begin
      Result := 1;
      Exit;
    end;
  end;
end;

function HasRuntimeAtLeast(const RootKey: Integer; const KeyPath: string; const Required: string): Boolean;
var
  Subkeys: TArrayOfString;
  I: Integer;
begin
  Result := False;
  if not RegGetSubkeyNames(RootKey, KeyPath, Subkeys) then
    Exit;
  for I := 0 to GetArrayLength(Subkeys) - 1 do
  begin
    if CompareVersion(Subkeys[I], Required) >= 0 then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function IsDesktopRuntime10Installed(): Boolean;
var
  Required: string;
begin
  Required := '10.0.0';
  Result :=
    HasRuntimeAtLeast(HKLM64, 'SOFTWARE\dotnet\Setup\InstalledVersions\x64\sharedfx\Microsoft.WindowsDesktop.App', Required) or
    HasRuntimeAtLeast(HKLM64, 'SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedfx\Microsoft.WindowsDesktop.App', Required) or
    HasRuntimeAtLeast(HKLM32, 'SOFTWARE\dotnet\Setup\InstalledVersions\x86\sharedfx\Microsoft.WindowsDesktop.App', Required) or
    HasRuntimeAtLeast(HKLM32, 'SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x86\sharedfx\Microsoft.WindowsDesktop.App', Required);
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
