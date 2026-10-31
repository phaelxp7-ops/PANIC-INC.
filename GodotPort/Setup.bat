@echo off
setlocal
pushd "%~dp0"
call "%~dp0FindGodot.bat"
if errorlevel 1 (popd & exit /b 1)
where git >nul 2>nul || (echo ERRO: instale Git para Windows. & popd & exit /b 1)
where git-lfs >nul 2>nul || (echo ERRO: instale Git LFS. & popd & exit /b 1)
where py >nul 2>nul || (echo ERRO: instale Python 3.11 ou mais recente. & popd & exit /b 1)
git lfs install
"%GODOT_EXE%" --headless --editor --path . --import --quit
if errorlevel 1 (popd & exit /b 1)
popd
echo Preparacao concluida. Use Run_Editor.bat ou Run_Game.bat.
