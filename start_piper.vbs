Set objFSO = CreateObject("Scripting.FileSystemObject")
Set WshShell = CreateObject("WScript.Shell")
strDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
WshShell.CurrentDirectory = strDir
WshShell.Run """" & strDir & "\ahk\AutoHotkey64.exe"" """ & strDir & "\speak_selected.ahk""", 0, False
