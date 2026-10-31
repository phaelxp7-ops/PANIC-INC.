@echo off
setlocal
pushd "%~dp0"
call "%~dp0FindGodot.bat"
if errorlevel 1 (popd & exit /b 1)
if not exist "build" mkdir "build"
"%GODOT_EXE%" --headless --path . --export-release "Windows Desktop" "build\PanicInc.exe"
set "RESULT=%ERRORLEVEL%"
popd
if not "%RESULT%"=="0" exit /b %RESULT%
echo Exportado em build\PanicInc.exe
