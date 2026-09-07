#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ==============================================================================
; Piper TTS - Озвучивание выделенного текста по горячим клавишам для Windows
; Горячая клавиша по умолчанию: Ctrl + Shift + Space (Старт / Стоп)
; Экстренный стоп:              Ctrl + Shift + Esc   или клавиша Pause
; ==============================================================================

appDir := A_ScriptDir
piperExe := appDir "\piper\piper.exe"
modelsDir := appDir "\models"
tempDir := A_Temp "\piper_tts"
configFile := appDir "\config.ini"

if !DirExist(tempDir)
    DirCreate(tempDir)

tempTxt := tempDir "\input.txt"
tempWav := tempDir "\output.wav"

; ------------------------------------------------------------------------------
; Чтение сохраненных настроек из config.ini
; ------------------------------------------------------------------------------
global currentHotkey := IniRead(configFile, "Settings", "Hotkey", "^+Space")
global currentModel  := IniRead(configFile, "Settings", "Model", "ru_RU-dmitri-medium.onnx")
global currentSpeed  := Float(IniRead(configFile, "Settings", "Speed", "1.0"))

; Список найденных моделей
global availableModels := []
global modelLabels := Map()
global speedOptions := [
    { label: "1.4x (Очень быстро)", val: 0.70 },
    { label: "1.2x (Быстро)",       val: 0.85 },
    { label: "1.0x (Нормально)",    val: 1.00 },
    { label: "0.85x (Медленнее)",   val: 1.18 }
]

global voiceMenu := Menu()
global speedMenu := Menu()
global hotkeyGuiObj := ""

loop files modelsDir "\*.onnx" {
    availableModels.Push(A_LoopFileName)
}

if (availableModels.Length > 0) {
    hasDefault := false
    for model in availableModels {
        if (model = currentModel) {
            hasDefault := true
            break
        }
    }
    if (!hasDefault) {
        currentModel := availableModels[1]
        IniWrite(currentModel, configFile, "Settings", "Model")
    }
} else {
    res := MsgBox("В папке models не найдено ни одной модели голоса.`n`nЗапустить загрузку голосов (download_voice.ps1)?", "Piper TTS", "YesNo Icon?")
    if (res = "Yes") {
        Run('powershell.exe -ExecutionPolicy Bypass -File "' appDir '\download_voice.ps1"')
    }
}

; ------------------------------------------------------------------------------
; Регистрация горячих клавиш
; ------------------------------------------------------------------------------

; Маскирование переключения языка Windows при нажатии Ctrl+Shift
A_MenuMaskKey := "vkE8"

MaskLayoutSwitch() {
    DllCall("keybd_event", "uchar", 0xE8, "uchar", 0, "uint", 0, "uptr", 0)
    DllCall("keybd_event", "uchar", 0xE8, "uchar", 0, "uint", 2, "uptr", 0)
}

; Функция применения горячей клавиши
ApplyHotkey(newHk) {
    global currentHotkey, configFile
    
    ; Снимаем старую комбинацию
    if (currentHotkey != "") {
        try Hotkey(currentHotkey, "Off")
    }

    try {
        Hotkey(newHk, OnHotkeyPressed, "On")
        currentHotkey := newHk
        IniWrite(currentHotkey, configFile, "Settings", "Hotkey")
        UpdateTrayMenuAndTip()
        return true
    } catch as err {
        ; Если регистрация не удалась, возвращаем старую
        if (currentHotkey != "")
            try Hotkey(currentHotkey, OnHotkeyPressed, "On")
        throw err
    }
}

; Регистрируем основную горячую клавишу
try {
    ApplyHotkey(currentHotkey)
} catch {
    ; Если сохраненная клавиша недопустима, сбрасываем на дефолтную
    ApplyHotkey("^+Space")
}

; Экстренные клавиши остановки (всегда активны)
^+Esc::StopPlayback()
Pause::StopPlayback()

; ------------------------------------------------------------------------------
; Обработчик нажатия горячей клавиши (Старт / Стоп)
; ------------------------------------------------------------------------------

OnHotkeyPressed(hk) {
    MaskLayoutSwitch()

    ; Если в данный момент воспроизводится звук — останавливаем его (Toggle)
    if IsAudioPlaying() {
        StopPlayback()
        ShowTempTooltip("⏹ Воспроизведение остановлено", 1000)
        return
    }

    ; Сохраняем предыдущий буфер обмена пользователя
    clipBackup := ClipboardAll()
    A_Clipboard := ""

    ; Отправляем Ctrl+C для копирования выделенного текста в активном окне
    Send("^c")
    MaskLayoutSwitch()

    ; Ждем появления текста в буфере (максимум 400 мс)
    if !ClipWait(0.4) {
        A_Clipboard := clipBackup
        MaskLayoutSwitch()
        ShowTempTooltip("Текст не выделен!", 1200)
        return
    }

    selectedText := Trim(A_Clipboard)
    
    ; Сразу восстанавливаем буфер обмена пользователя
    A_Clipboard := clipBackup
    MaskLayoutSwitch()

    if (selectedText == "") {
        ShowTempTooltip("Выделенный текст пуст!", 1200)
        return
    }

    ; Запуск озвучки
    SpeakText(selectedText)
}

; ------------------------------------------------------------------------------
; Функции синтеза и воспроизведения звука (MCI)
; ------------------------------------------------------------------------------

IsAudioPlaying() {
    buf := Buffer(128, 0)
    DllCall("winmm\mciSendStringW", "wstr", "status piperAudio mode", "ptr", buf.Ptr, "uint", 64, "ptr", 0)
    mode := StrGet(buf.Ptr)
    return (mode = "playing")
}

StopPlayback() {
    DllCall("winmm\mciSendStringW", "wstr", "stop piperAudio", "ptr", 0, "uint", 0, "ptr", 0)
    DllCall("winmm\mciSendStringW", "wstr", "close piperAudio", "ptr", 0, "uint", 0, "ptr", 0)
    DllCall("winmm\PlaySoundW", "ptr", 0, "ptr", 0, "uint", 0)
    ToolTip()
}

PlayWav(wavPath) {
    StopPlayback()
    DllCall("winmm\mciSendStringW", "wstr", 'open "' wavPath '" type waveaudio alias piperAudio', "ptr", 0, "uint", 0, "ptr", 0)
    DllCall("winmm\mciSendStringW", "wstr", "play piperAudio", "ptr", 0, "uint", 0, "ptr", 0)
}

SpeakText(text) {
    global piperExe, modelsDir, currentModel, currentSpeed, tempTxt, tempWav, currentHotkey

    modelPath := modelsDir "\" currentModel
    configPath := modelPath ".json"

    if !FileExist(modelPath) {
        MsgBox("Модель голоса не найдена:`n" modelPath, "Ошибка Piper TTS", "Icon!")
        return
    }

    if !FileExist(piperExe) {
        MsgBox("Файл piper.exe не найден по пути:`n" piperExe, "Ошибка Piper TTS", "Icon!")
        return
    }

    ; Перед синтезом обязательно освобождаем аудиофайл
    StopPlayback()

    ; Удаляем старый файл wav, чтобы гарантировать генерацию нового
    if FileExist(tempWav) {
        try FileDelete(tempWav)
    }

    ; Записываем текст во временный файл в кодировке UTF-8
    try {
        if FileExist(tempTxt)
            FileDelete(tempTxt)
        fileObj := FileOpen(tempTxt, "w", "UTF-8")
        fileObj.Write(text)
        fileObj.Close()
    } catch as err {
        ShowTempTooltip("Ошибка записи текста: " err.Message, 2000)
        return
    }

    ShowTempTooltip("⏳ Генерация речи...", 5000)

    ; Формируем команду вызова piper.exe с явным указанием модели и конфига
    cmd := A_ComSpec ' /c chcp 65001 >nul && "' piperExe '" -m "' modelPath '" -c "' configPath '" --length_scale ' currentSpeed ' -f "' tempWav '" < "' tempTxt '"'

    ; Выполняем синтез без появления черного окна консоли (Hide)
    exitCode := RunWait(cmd,, "Hide")

    if (exitCode != 0 || !FileExist(tempWav) || FileGetSize(tempWav) = 0) {
        ShowTempTooltip("Ошибка генерации звука Piper!", 2500)
        return
    }

    ; Запуск воспроизведения через MCI
    PlayWav(tempWav)
    readableHk := GetReadableHotkey(currentHotkey)
    ShowTempTooltip("🔊 Озвучивание... (" readableHk " — стоп)", 3000)
}

ShowTempTooltip(msg, durationMs := 1500) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -durationMs)
}

; ------------------------------------------------------------------------------
; Преобразование комбинации клавиш в читаемый вид
; ------------------------------------------------------------------------------

GetReadableHotkey(hk) {
    if (hk == "")
        return "Не назначена"

    parts := []
    cleanHk := hk

    hasCtrl := false
    hasShift := false
    hasAlt := false
    hasWin := false

    loop {
        ch := SubStr(cleanHk, 1, 1)
        if (ch = "^") {
            hasCtrl := true
            cleanHk := SubStr(cleanHk, 2)
        } else if (ch = "+") {
            hasShift := true
            cleanHk := SubStr(cleanHk, 2)
        } else if (ch = "!") {
            hasAlt := true
            cleanHk := SubStr(cleanHk, 2)
        } else if (ch = "#") {
            hasWin := true
            cleanHk := SubStr(cleanHk, 2)
        } else {
            break
        }
    }

    if hasCtrl
        parts.Push("Ctrl")
    if hasAlt
        parts.Push("Alt")
    if hasShift
        parts.Push("Shift")
    if hasWin
        parts.Push("Win")

    if (cleanHk != "")
        parts.Push(cleanHk)

    result := ""
    for idx, part in parts {
        result .= (idx > 1 ? " + " : "") . part
    }
    return result
}

; ------------------------------------------------------------------------------
; Настройка меню в системном трее
; ------------------------------------------------------------------------------

InitTrayMenu() {
    global availableModels, currentModel, currentSpeed, voiceMenu, speedMenu, modelLabels, speedOptions

    ; Заполняем подменю голосов
    for model in availableModels {
        label := model
        if InStr(model, "dmitri")
            label := "Дмитрий (dmitri) [RU]"
        else if InStr(model, "irina")
            label := "Ирина (irina) [RU]"
        else if InStr(model, "ruslan")
            label := "Руслан (ruslan) [RU]"
        else if InStr(model, "denis")
            label := "Денис (denis) [RU]"
        
        modelLabels[model] := label
        voiceMenu.Add(label, MenuSelectVoice.Bind(model))
        if (model = currentModel)
            voiceMenu.Check(label)
    }

    ; Заполняем подменю скорости
    for opt in speedOptions {
        speedMenu.Add(opt.label, MenuSelectSpeed.Bind(opt.val))
        if (opt.val = currentSpeed)
            speedMenu.Check(opt.label)
    }

    UpdateTrayMenuAndTip()
}

UpdateTrayMenuAndTip() {
    global currentModel, modelLabels, currentHotkey, voiceMenu, speedMenu, modelsDir

    tray := A_TrayMenu
    tray.Delete()

    tray.Add("Piper TTS — Готов к работе", (*) => {})
    tray.Disable("Piper TTS — Готов к работе")

    readableHk := GetReadableHotkey(currentHotkey)
    tray.Add("Горячая клавиша: " readableHk, (*) => ShowHotkeyDialog())
    tray.Add("Настроить горячую клавишу...", (*) => ShowHotkeyDialog())
    tray.Add()

    tray.Add("Выбор голоса", voiceMenu)
    tray.Add("Скорость речи", speedMenu)
    tray.Add()

    tray.Add("Папка с моделями", (*) => Run(modelsDir))
    tray.Add("Добавить в автозагрузку Windows", ToggleStartup)
    if IsInStartup()
        tray.Check("Добавить в автозагрузку Windows")

    tray.Add("Остановить речь", (*) => StopPlayback())
    tray.Add("Выход", (*) => ExitApp())

    activeLabel := modelLabels.Has(currentModel) ? modelLabels[currentModel] : currentModel
    A_IconTip := "Piper TTS`nГолос: " activeLabel "`nКлавиша: " readableHk " (Старт/Стоп)"
}

; Вызов меню смены голоса
MenuSelectVoice(selectedModel, itemName, itemPos, myMenu) {
    global currentModel, voiceMenu, modelLabels, configFile

    for model, label in modelLabels {
        try voiceMenu.Uncheck(label)
    }
    if modelLabels.Has(selectedModel)
        try voiceMenu.Check(modelLabels[selectedModel])

    currentModel := selectedModel
    IniWrite(currentModel, configFile, "Settings", "Model")
    UpdateTrayMenuAndTip()
    ShowTempTooltip("Выбран голос: " itemName, 1500)
}

; Вызов меню смены скорости
MenuSelectSpeed(speedVal, itemName, itemPos, myMenu) {
    global currentSpeed, speedMenu, speedOptions, configFile

    for opt in speedOptions {
        try speedMenu.Uncheck(opt.label)
    }
    try speedMenu.Check(itemName)

    currentSpeed := speedVal
    IniWrite(currentSpeed, configFile, "Settings", "Speed")
    ShowTempTooltip("Установлена скорость: " itemName, 1500)
}

; ------------------------------------------------------------------------------
; Графическое окно выбора горячей клавиши
; ------------------------------------------------------------------------------

CloseHotkeyGui(*) {
    global hotkeyGuiObj
    if (hotkeyGuiObj != "") {
        try hotkeyGuiObj.Destroy()
        hotkeyGuiObj := ""
    }
}

ShowHotkeyDialog() {
    global currentHotkey, hotkeyGuiObj

    if (hotkeyGuiObj != "") {
        try {
            if WinExist(hotkeyGuiObj) {
                hotkeyGuiObj.Show()
                return
            }
        }
        hotkeyGuiObj := ""
    }

    myGui := Gui("+AlwaysOnTop -MinimizeBox", "Настройка горячей клавиши — Piper TTS")
    myGui.SetFont("s10", "Segoe UI")

    myGui.OnEvent("Close", CloseHotkeyGui)
    myGui.OnEvent("Escape", CloseHotkeyGui)

    myGui.Add("Text", "w340", "Текущая комбинация клавиш:")
    myGui.SetFont("s11 bold")
    txtCurrent := myGui.Add("Text", "w340 c0055AA", GetReadableHotkey(currentHotkey))
    myGui.SetFont("s10 norm")

    myGui.Add("Text", "w340 y+12", "Нажмите новую комбинацию в поле:")
    hkInput := myGui.Add("Hotkey", "w340", currentHotkey)

    myGui.Add("Text", "w340 y+12", "Или выберите быстрый пресет:")
    presets := [
        "Ctrl + Shift + Space",
        "Ctrl + Alt + Space",
        "Ctrl + Shift + S",
        "Alt + Shift + S",
        "Ctrl + Space",
        "F9",
        "F8"
    ]
    presetMap := Map(
        "Ctrl + Shift + Space", "^+Space",
        "Ctrl + Alt + Space",   "^!Space",
        "Ctrl + Shift + S",     "^+s",
        "Alt + Shift + S",       "!+s",
        "Ctrl + Space",         "^Space",
        "F9",                   "F9",
        "F8",                   "F8"
    )
    ddl := myGui.Add("DropDownList", "w340", presets)
    ddl.OnEvent("Change", (ctrl, *) => (presetMap.Has(ctrl.Text) ? hkInput.Value := presetMap[ctrl.Text] : 0))

    btnSave := myGui.Add("Button", "y+18 w100 Default", "Сохранить")
    btnReset := myGui.Add("Button", "x+10 w110", "По умолчанию")
    btnCancel := myGui.Add("Button", "x+10 w100", "Отмена")

    btnSave.OnEvent("Click", (*) => OnSaveHotkeyClick(hkInput.Value))
    btnReset.OnEvent("Click", (*) => (hkInput.Value := "^+Space"))
    btnCancel.OnEvent("Click", CloseHotkeyGui)

    hotkeyGuiObj := myGui
    myGui.Show("w370")
}

OnSaveHotkeyClick(newHk) {
    newHk := Trim(newHk)
    if (newHk == "") {
        MsgBox("Пожалуйста, нажмите или выберите комбинацию клавиш.", "Piper TTS", "Icon!")
        return
    }

    try {
        ApplyHotkey(newHk)
        readable := GetReadableHotkey(newHk)
        CloseHotkeyGui()
        ShowTempTooltip("Горячая клавиша сохранена: " readable, 2000)
    } catch as err {
        MsgBox("Не удалось назначить эту комбинацию клавиш:`n" err.Message "`n`nВозможно, она зарезервирована системой или другой программой.", "Ошибка горячей клавиши", "Icon!")
    }
}

; ------------------------------------------------------------------------------
; Управление автозагрузкой (shell:startup)
; ------------------------------------------------------------------------------

GetStartupShortcutPath() {
    return A_Startup "\PiperTTS.lnk"
}

IsInStartup() {
    return FileExist(GetStartupShortcutPath())
}

ToggleStartup(*) {
    shortcut := GetStartupShortcutPath()
    tray := A_TrayMenu
    if FileExist(shortcut) {
        FileDelete(shortcut)
        tray.Uncheck("Добавить в автозагрузку Windows")
        ShowTempTooltip("Piper TTS удален из автозагрузки", 1500)
    } else {
        vbsLauncher := A_ScriptDir "\start_piper.vbs"
        FileCreateShortcut(vbsLauncher, shortcut, A_ScriptDir,, "Piper TTS hotkey speaker", A_ScriptDir "\piper\piper.exe")
        tray.Check("Добавить в автозагрузку Windows")
        ShowTempTooltip("Piper TTS добавлен в автозагрузку Windows!", 1500)
    }
}

; Запуск меню при старте
InitTrayMenu()
