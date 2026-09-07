"""
Piper TTS Hotkey Reader (Альтернативный вариант на чистом Python)

Установка зависимостей:
    pip install keyboard pyperclip

Запуск в фоне:
    pythonw piper_hotkey.py
"""

import os
import subprocess
import tempfile
import time
import winsound

try:
    import keyboard
    import pyperclip
except ImportError:
    print("Не установлены зависимости. Выполните: pip install keyboard pyperclip")
    exit(1)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PIPER_EXE = os.path.join(SCRIPT_DIR, "piper", "piper.exe")
MODEL_PATH = os.path.join(SCRIPT_DIR, "models", "ru_RU-dmitri-medium.onnx")

def speak_selected():
    try:
        old_clip = pyperclip.paste()
    except Exception:
        old_clip = ""

    # Имитируем Ctrl+C для получения текста
    keyboard.send("ctrl+c")
    time.sleep(0.2)

    try:
        text = pyperclip.paste().strip()
    except Exception:
        text = ""

    # Восстанавливаем буфер
    try:
        pyperclip.copy(old_clip)
    except Exception:
        pass

    if not text:
        return

    temp_wav = os.path.join(tempfile.gettempdir(), "piper_py_output.wav")

    # Генерация звука через piper.exe
    p = subprocess.Popen(
        [PIPER_EXE, "-m", MODEL_PATH, "-f", temp_wav],
        stdin=subprocess.PIPE,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
    )
    p.communicate(input=text.encode("utf-8"))

    # Воспроизведение звука без внешних плееров (нативный Windows API)
    if os.path.exists(temp_wav):
        winsound.PlaySound(temp_wav, winsound.SND_ASYNC | winsound.SND_FILENAME)

def stop_playback():
    winsound.PlaySound(None, winsound.SND_PURGE)

if __name__ == "__main__":
    print("Piper TTS (Python) запущен.")
    print("Горячая клавиша: Ctrl+Shift+Space (Озвучить / Стоп)")
    keyboard.add_hotkey("ctrl+shift+space", speak_selected)
    keyboard.add_hotkey("ctrl+shift+esc", stop_playback)
    keyboard.wait()
