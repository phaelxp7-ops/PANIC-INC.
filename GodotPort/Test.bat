@echo off
setlocal EnableDelayedExpansion
pushd "%~dp0"
call "%~dp0FindGodot.bat" || exit /b 1
"%GODOT_EXE%" --headless --editor --path . --import --quit || exit /b 1
"%GODOT_EXE%" --headless --path . -s addons/gut/gut_cmdln.gd -gexit -gexit_on_success -gdisable_colors || exit /b 1
where gdlint >nul 2>nul
if not errorlevel 1 (
	gdlint scripts tests
  if errorlevel 1 exit /b 1
) else (
  set "GDLINT_FOUND="
  for /d %%D in ("%APPDATA%\Python\Python*") do if exist "%%~fD\Scripts\gdlint.exe" (
    "%%~fD\Scripts\gdlint.exe" scripts tests
    if errorlevel 1 exit /b 1
    set "GDLINT_FOUND=1"
  )
  if not defined GDLINT_FOUND (
    echo Aviso: gdlint nao encontrado. Instale com: py -m pip install --user gdtoolkit
  )
)
echo Testes concluidos.
popd
