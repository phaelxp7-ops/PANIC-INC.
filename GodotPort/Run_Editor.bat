@echo off
setlocal
pushd "%~dp0"
call "%~dp0FindGodot.bat" || (popd & exit /b 1)
start "PANIC INC. — Godot Editor" "%GODOT_EXE%" --editor --path .
popd
