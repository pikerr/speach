; ==============================================================================
; Piper TTS for Windows - Inno Setup Script
; Сетевой (онлайн) установщик с выбором и фоновой загрузкой голосов
; ==============================================================================

#define MyAppName "Piper TTS"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "pikerr"
#define MyAppURL "https://github.com/pikerr/piper-win"
#define MyAppExeName "start_piper.vbs"

[Setup]
AppId={{8B7812A4-F51D-491F-B95D-8A7E4F28C3E1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}/releases
; Установка для текущего пользователя без прав администратора
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=commandline
DefaultDirName={autopf}\Piper TTS
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=dist
OutputBaseFilename=PiperTTS_Setup
SetupIconFile=ahk\UX\inc\spy.ico
UninstallDisplayIcon={app}\ahk\AutoHotkey64.exe
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern dynamic

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
russian.ComponentsTitle=Выбор голосов для загрузки
russian.ComponentsDesc=Отметьте голосовые модели, которые нужно скачать во время установки:
russian.VoicesGroup=Голосовые модели Piper (загрузка из интернета)
russian.VoiceDmitri=Русский: Дмитрий (Мужской, ~60 МБ)
russian.VoiceIrina=Русский: Ирина (Женский, ~60 МБ)
russian.VoiceRuslan=Русский: Руслан (Мужской, ~60 МБ)
russian.VoiceDenis=Русский: Денис (Мужской, ~60 МБ)
russian.VoiceLessac=English: Lessac (Женский, ~60 МБ)
russian.VoiceRyan=English: Ryan (Мужской, ~60 МБ)
russian.DesktopIcon=Создать ярлык на Рабочем столе
russian.StartupTask=Запускать Piper TTS при входе в Windows
russian.LaunchProgram=Запустить Piper TTS прямо сейчас
russian.NoVoiceWarning=Вы не выбрали ни одного голоса для загрузки.%n%nPiper TTS требует хотя бы одну голосовую модель для синтеза речи.%nВы действительно хотите продолжить установку без голосов?

english.ComponentsTitle=Voice Model Selection
english.ComponentsDesc=Select the voice models you want to download during installation:
english.VoicesGroup=Piper Voice Models (online download)
english.VoiceDmitri=Russian: Dmitri (Male, ~60 MB)
english.VoiceIrina=Russian: Irina (Female, ~60 MB)
english.VoiceRuslan=Russian: Ruslan (Male, ~60 MB)
english.VoiceDenis=Russian: Denis (Male, ~60 MB)
english.VoiceLessac=English: Lessac (Female, ~60 MB)
english.VoiceRyan=English: Ryan (Male, ~60 MB)
english.DesktopIcon=Create a desktop shortcut
english.StartupTask=Start Piper TTS on Windows startup
english.LaunchProgram=Launch Piper TTS right now
english.NoVoiceWarning=You have not selected any voice model to download.%n%nPiper TTS requires at least one model to speak text.%nAre you sure you want to continue without voices?

[Types]
Name: "default"; Description: "Рекомендуемая (Дмитрий + Ирина)"
Name: "full"; Description: "Полная (все доступные голоса)"
Name: "custom"; Description: "Выборочная установка"; Flags: iscustom

[Components]
Name: "core"; Description: "Движок Piper TTS и скрипты горячих клавиш"; Types: default full custom; Flags: fixed
Name: "voices"; Description: "{cm:VoicesGroup}"; Types: default full custom; Flags: fixed
Name: "voices\dmitri"; Description: "{cm:VoiceDmitri}"; Types: default full custom
Name: "voices\irina"; Description: "{cm:VoiceIrina}"; Types: default full custom
Name: "voices\ruslan"; Description: "{cm:VoiceRuslan}"; Types: full
Name: "voices\denis"; Description: "{cm:VoiceDenis}"; Types: full
Name: "voices\lessac"; Description: "{cm:VoiceLessac}"; Types: full
Name: "voices\ryan"; Description: "{cm:VoiceRyan}"; Types: full

[Tasks]
Name: "desktopicon"; Description: "{cm:DesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "startup"; Description: "{cm:StartupTask}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; --- Основные локальные файлы программы ---
Source: "piper\*"; DestDir: "{app}\piper"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: core
Source: "ahk\*"; DestDir: "{app}\ahk"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: core
Source: "speak_selected.ahk"; DestDir: "{app}"; Flags: ignoreversion; Components: core
Source: "start_piper.vbs"; DestDir: "{app}"; Flags: ignoreversion; Components: core
Source: "start_piper.bat"; DestDir: "{app}"; Flags: ignoreversion; Components: core
Source: "stop_piper.bat"; DestDir: "{app}"; Flags: ignoreversion; Components: core
Source: "download_voice.ps1"; DestDir: "{app}"; Flags: ignoreversion; Components: core
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion; Components: core
Source: "config.ini"; DestDir: "{app}"; Flags: onlyifdoesntexist; Components: core
Source: "models\.gitkeep"; DestDir: "{app}\models"; Flags: ignoreversion; Components: core

; --- Сетевая загрузка голосовых моделей (HuggingFace) ---
; Дмитрий (ru_RU)
Source: "https://huggingface.co/rhasspy/piper-voices/resolve/main/ru/ru_RU/dmitri/medium/ru_RU-dmitri-medium.onnx"; \
  DestName: "ru_RU-dmitri-medium.onnx"; DestDir: "{app}\models"; ExternalSize: 63201294; Flags: external download ignoreversion; Components: voices\dmitri
Source: "https://huggingface.co/rhasspy/piper-voices/resolve/main/ru/ru_RU/dmitri/medium/ru_RU-dmitri-medium.onnx.json"; \
  DestName: "ru_RU-dmitri-medium.onnx.json"; DestDir: "{app}\models"; ExternalSize: 4824; Flags: external download ignoreversion; Components: voices\dmitri

; Ирина (ru_RU)
Source: "https://huggingface.co/rhasspy/piper-voices/resolve/main/ru/ru_RU/irina/medium/ru_RU-irina-medium.onnx"; \
  DestName: "ru_RU-irina-medium.onnx"; DestDir: "{app}\models"; ExternalSize: 63201294; Flags: external download ignoreversion; Components: voices\irina
Source: "https://huggingface.co/rhasspy/piper-voices/resolve/main/ru/ru_RU/irina/medium/ru_RU-irina-medium.onnx.json"; \
  DestName: "ru_RU-irina-medium.onnx.json"; DestDir: "{app}\models"; ExternalSize: 4765; Flags: external download ignoreversion; Components: voices\irina

; Руслан (ru_RU)
Source: "https://huggingface.co/rhasspy/piper-voices/resolve/main/ru/ru_RU/ruslan/medium/ru_RU-ruslan-medium.onnx"; \
  DestName: "ru_RU-ruslan-medium.onnx"; DestDir: "{app}\models"; ExternalSize: 63201294; Flags: external download ignoreversion; Components: voices\ruslan
Source: "https://huggingface.co/rhasspy/piper-voices/resolve/main/ru/ru_RU/ruslan/medium/ru_RU-ruslan-medium.onnx.json"; \
  DestName: "ru_RU-ruslan-medium.onnx.json"; DestDir: "{app}\models"; ExternalSize: 4800; Flags: external download ignoreversion; Components: voices\ruslan

; Денис (ru_RU)
Source: "https://huggingface.co/rhasspy/piper-voices/resolve/main/ru/ru_RU/denis/medium/ru_RU-denis-medium.onnx"; \
  DestName: "ru_RU-denis-medium.onnx"; DestDir: "{app}\models"; ExternalSize: 63201294; Flags: external download ignoreversion; Components: voices\denis
Source: "https://huggingface.co/rhasspy/piper-voices/resolve/main/ru/ru_RU/denis/medium/ru_RU-denis-medium.onnx.json"; \
  DestName: "ru_RU-denis-medium.onnx.json"; DestDir: "{app}\models"; ExternalSize: 4800; Flags: external download ignoreversion; Components: voices\denis

; Lessac (en_US)
Source: "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx"; \
  DestName: "en_US-lessac-medium.onnx"; DestDir: "{app}\models"; ExternalSize: 63201294; Flags: external download ignoreversion; Components: voices\lessac
Source: "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json"; \
  DestName: "en_US-lessac-medium.onnx.json"; DestDir: "{app}\models"; ExternalSize: 4800; Flags: external download ignoreversion; Components: voices\lessac

; Ryan (en_US)
Source: "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/medium/en_US-ryan-medium.onnx"; \
  DestName: "en_US-ryan-medium.onnx"; DestDir: "{app}\models"; ExternalSize: 63201294; Flags: external download ignoreversion; Components: voices\ryan
Source: "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/medium/en_US-ryan-medium.onnx.json"; \
  DestName: "en_US-ryan-medium.onnx.json"; DestDir: "{app}\models"; ExternalSize: 4800; Flags: external download ignoreversion; Components: voices\ryan

[Icons]
Name: "{autoprograms}\{#MyAppName}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\ahk\AutoHotkey64.exe"
Name: "{autoprograms}\{#MyAppName}\Остановить {#MyAppName}"; Filename: "{app}\stop_piper.bat"; IconFilename: "{sys}\shell32.dll"; IconIndex: 27
Name: "{autoprograms}\{#MyAppName}\Папка с моделями голосов"; Filename: "{app}\models"
Name: "{autoprograms}\{#MyAppName}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\ahk\AutoHotkey64.exe"; Tasks: desktopicon
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\ahk\AutoHotkey64.exe"; Tasks: startup

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram}"; Flags: shellexec postinstall nowait skipifsilent

[UninstallRun]
Filename: "{app}\stop_piper.bat"; Flags: runhidden; RunOnceId: "StopPiperTTS"

[UninstallDelete]
Type: files; Name: "{app}\config.ini"
Type: filesandordirs; Name: "{localappdata}\Temp\piper_tts"

[Code]
// Остановка фонового процесса AutoHotkey перед установкой / удалением
procedure StopPiperProcess;
var
  ResultCode: Integer;
begin
  Exec('cmd.exe', '/c taskkill /f /im AutoHotkey64.exe >nul 2>&1', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

function InitializeSetup(): Boolean;
begin
  StopPiperProcess();
  Result := True;
end;

function InitializeUninstall(): Boolean;
begin
  StopPiperProcess();
  Result := True;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  AnyVoiceSelected: Boolean;
begin
  Result := True;
  if CurPageID = wpSelectComponents then
  begin
    AnyVoiceSelected := WizardIsComponentSelected('voices\dmitri') or
                        WizardIsComponentSelected('voices\irina') or
                        WizardIsComponentSelected('voices\ruslan') or
                        WizardIsComponentSelected('voices\denis') or
                        WizardIsComponentSelected('voices\lessac') or
                        WizardIsComponentSelected('voices\ryan');
    if not AnyVoiceSelected then
    begin
      if MsgBox(CustomMessage('NoVoiceWarning'), mbConfirmation, MB_YESNO) <> IDYES then
      begin
        Result := False;
      end;
    end;
  end;
end;
