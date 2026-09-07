param (
    [string]$Voice = ""
)

$modelsDir = Join-Path $PSScriptRoot "models"
if (-not (Test-Path $modelsDir)) {
    New-Item -ItemType Directory -Path $modelsDir | Out-Null
}

$voiceCatalog = @{
    "1" = @{ Name = "ru_RU-dmitri-medium";  Lang = "ru/ru_RU/dmitri/medium"; Desc = "Русский (Мужской - Дмитрий)" }
    "2" = @{ Name = "ru_RU-irina-medium";   Lang = "ru/ru_RU/irina/medium";  Desc = "Русский (Женский - Ирина)" }
    "3" = @{ Name = "ru_RU-ruslan-medium";  Lang = "ru/ru_RU/ruslan/medium"; Desc = "Русский (Мужской - Руслан)" }
    "4" = @{ Name = "ru_RU-denis-medium";   Lang = "ru/ru_RU/denis/medium";  Desc = "Русский (Мужской - Денис)" }
    "5" = @{ Name = "en_US-lessac-medium";  Lang = "en/en_US/lessac/medium"; Desc = "English (Female - Lessac)" }
    "6" = @{ Name = "en_US-ryan-medium";    Lang = "en/en_US/ryan/medium";   Desc = "English (Male - Ryan)" }
}

$selected = $null

if ($Voice -ne "") {
    foreach ($v in $voiceCatalog.Values) {
        if ($v.Name -eq $Voice) {
            $selected = $v
            break
        }
    }
}

if ($null -eq $selected) {
    Write-Host "=== Каталог доступных голосов Piper ===" -ForegroundColor Cyan
    foreach ($key in ($voiceCatalog.Keys | Sort-Object)) {
        $item = $voiceCatalog[$key]
        $installed = if (Test-Path (Join-Path $modelsDir "$($item.Name).onnx")) { "[Уже скачан]" } else { "" }
        Write-Host " [$key] $($item.Desc) $installed"
    }
    Write-Host ""
    $choice = Read-Host "Введите номер голоса для загрузки (1-6)"
    if ($voiceCatalog.ContainsKey($choice)) {
        $selected = $voiceCatalog[$choice]
    } else {
        Write-Host "Отмена или неверный выбор." -ForegroundColor Yellow
        exit
    }
}

$name = $selected.Name
$lang = $selected.Lang
$onnxUrl = "https://huggingface.co/rhasspy/piper-voices/resolve/main/$lang/$name.onnx"
$jsonUrl = "https://huggingface.co/rhasspy/piper-voices/resolve/main/$lang/$name.onnx.json"

$onnxTarget = Join-Path $modelsDir "$name.onnx"
$jsonTarget = Join-Path $modelsDir "$name.onnx.json"

Write-Host "Скачивание модели $name..." -ForegroundColor Green
Invoke-WebRequest -Uri $onnxUrl -OutFile $onnxTarget
Invoke-WebRequest -Uri $jsonUrl -OutFile $jsonTarget

Write-Host "Готово! Модель сохранена в models/$name.onnx" -ForegroundColor Green
Write-Host "Перезапустите Piper TTS или выберите голос в меню трея." -ForegroundColor Yellow
