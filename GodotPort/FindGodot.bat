@echo off
if defined GODOT_EXE if exist "%GODOT_EXE%" exit /b 0
if exist "E:\GameDev\Godot\4.7.2\Godot_v4.7.2-stable_win64.exe" (set "GODOT_EXE=E:\GameDev\Godot\4.7.2\Godot_v4.7.2-stable_win64.exe" & exit /b 0)
if exist "%~dp0tools\godot\Godot_v4.7.2-stable_win64.exe" (set "GODOT_EXE=%~dp0tools\godot\Godot_v4.7.2-stable_win64.exe" & exit /b 0)
echo ERRO: defina GODOT_EXE ou coloque Godot 4.7.2 em tools\godot\.
exit /b 1
