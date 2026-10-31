@echo off
setlocal
pushd "%~dp0"
call "%~dp0FindGodot.bat"
if errorlevel 1 goto :falha
start "Panic host" "%GODOT_EXE%" --headless --path . -- --panic-server
ping -n 3 127.0.0.1 >nul
start "Panic cliente 1" "%GODOT_EXE%" --path . -- --panic-join=127.0.0.1
start "Panic cliente 2" "%GODOT_EXE%" --path . -- --panic-join=127.0.0.1
popd
exit /b 0

:falha
popd
exit /b 1
