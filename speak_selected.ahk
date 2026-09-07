#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ==============================================================================
; Piper TTS - Озвучивание выделенного текста по горячим клавишам для Windows
; Горячая клавиша: Ctrl + Shift + Space  (Старт / Стоп)
; Экстренный стоп: Ctrl + Shift + Esc    или клавиша Pause
; ==============================================================================

appDir := A_ScriptDir
piperExe := appDir "\piper\piper.exe"
modelsDir := appDir "\models"
tempDir := A_Temp "\piper_tts"

if !DirExist(tempDir)
    DirCreate(tempDir)

tempTxt := tempDir "\input.txt"
tempWav := tempDir "\output.wav"

; Настройки по умолчанию
global currentSpeed := 1.0
global currentModel := "ru_RU-dmitri-medium.onnx"

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
    if (!hasDefault)
        currentModel := availableModels[1]
} else {
    res := MsgBox("В папке models не найдено ни одной модели голоса.`n`nЗапустить загрузку голосов (download_voice.ps1)?", "Piper TTS", "YesNo Icon?")
    if (res = "Yes") {
        Run('powershell.exe -ExecutionPolicy Bypass -File "' appDir '\download_voice.ps1"')
    }
}

; Инициализация меню в трее
InitTrayMenu()

; Предотвращаем срабатывание переключения раскладки клавиатуры (Ctrl+Shift) в Windows
A_MenuMaskKey := "vkE8"

MaskLayoutSwitch() {
    DllCall("keybd_event", "uchar", 0xE8, "uchar", 0, "uint", 0, "uptr", 0)
    DllCall("keybd_event", "uchar", 0xE8, "uchar", 0, "uint", 2, "uptr", 0)
}

; ------------------------------------------------------------------------------
; Горячая клавиша: Ctrl + Shift + Space (Старт / Стоп)
; ------------------------------------------------------------------------------

^+Space::
{
    ; Сбрасываем триггер смены языка Windows
    MaskLayoutSwitch()

    ; Если в данный момент уже воспроизводится звук — останавливаем его и выходим
    if IsAudioPlaying() {
        StopPlayback()
        ShowTempTooltip("⏹ Воспроизведение остановлено", 1000)
        return
    }

    ; Сохраняем предыдущее содержимое буфера обмена пользователя
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

; Экстренная остановка
^+Esc::StopPlayback()
Pause::StopPlayback()

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
    global piperExe, modelsDir, currentModel, currentSpeed, tempTxt, tempWav

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
    ShowTempTooltip("🔊 Озвучивание... (Ctrl+Shift+Space — стоп)", 3000)
}

ShowTempTooltip(msg, durationMs := 1500) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -durationMs)
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

    tray := A_TrayMenu
    tray.Delete()

    tray.Add("Piper TTS — Готов к работе", (*) => {})
    tray.Disable("Piper TTS — Готов к работе")
    tray.Add("Горячая клавиша: Ctrl+Shift+Space", (*) => {})
    tray.Disable("Горячая клавиша: Ctrl+Shift+Space")
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

    UpdateTrayTip()
}

UpdateTrayTip() {
    global currentModel, modelLabels
    activeLabel := modelLabels.Has(currentModel) ? modelLabels[currentModel] : currentModel
    A_IconTip := "Piper TTS`nГолос: " activeLabel "`nCtrl+Shift+Space — Старт / Стоп"
}

MenuSelectVoice(selectedModel, itemName, itemPos, myMenu) {
    global currentModel, voiceMenu, modelLabels

    ; Снимаем галочки со всех голосов
    for model, label in modelLabels {
        try voiceMenu.Uncheck(label)
    }

    ; Ставим галочку на выбранную модель
    if modelLabels.Has(selectedModel)
        try voiceMenu.Check(modelLabels[selectedModel])

    currentModel := selectedModel
    UpdateTrayTip()
    ShowTempTooltip("Выбран голос: " itemName, 1500)
}

MenuSelectSpeed(speedVal, itemName, itemPos, myMenu) {
    global currentSpeed, speedMenu, speedOptions

    for opt in speedOptions {
        try speedMenu.Uncheck(opt.label)
    }
    try speedMenu.Check(itemName)

    currentSpeed := speedVal
    ShowTempTooltip("Установлена скорость: " itemName, 1500)
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
