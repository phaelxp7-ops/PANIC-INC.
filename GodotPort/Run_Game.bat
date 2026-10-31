@echo off
setlocal
pushd "%~dp0"
call "%~dp0FindGodot.bat" || (popd & exit /b 1)
start "PANIC INC. — Jogo" "%GODOT_EXE%" --path .
popd
