@echo off
setlocal
pushd "%~dp0"
call "%~dp0FindGodot.bat" || (popd & exit /b 1)
"%GODOT_EXE%" --headless --path . -- --panic-server
set "RESULT=%ERRORLEVEL%"
popd
exit /b %RESULT%
