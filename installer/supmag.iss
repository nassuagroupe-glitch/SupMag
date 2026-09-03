; Script Inno Setup pour SupMag
#define MyAppName "SupMag"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Nassua Groupe"
#define MyAppExeName "supmag.exe"
#define MySourceDir "C:\Users\surface\Documents\SupMag\build\windows\x64\runner\Release"

[Setup]
AppId={{B6C1D9A2-4E3F-4A8B-9C2D-1F5E7A8B9C10}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=C:\Users\surface\Desktop\Logiciels .EXE
OutputBaseFilename=SupMag-Setup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
SetupIconFile=C:\Users\surface\Documents\SupMag\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#MySourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
