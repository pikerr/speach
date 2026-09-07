@echo off
chcp 65001 >nul
cd /d "%~dp0"
start "" "%~dp0ahk\AutoHotkey64.exe" "%~dp0speak_selected.ahk"
echo Piper TTS started in background.
echo Hotkey: Ctrl+Shift+Space (Speak), Ctrl+Shift+Esc (Stop)
