@echo off
chcp 65001 > nul
title Запуск Edge TTS Studio
color 06
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"
echo ==================================================
echo           Запуск Microsoft Edge TTS Studio         
echo ==================================================
echo.
set CONDA_PATH=%USERPROFILE%\miniconda3
if not exist "%CONDA_PATH%" set CONDA_PATH=%USERPROFILE%\anaconda3
set "ENV_FOUND=0"
if exist "%CONDA_PATH%" goto ACTIVATE_CONDA
goto CHECK_VENV
:ACTIVATE_CONDA
echo [INFO] Найдена Conda. Проверяем окружение 'edge-tts-env'...
call "%CONDA_PATH%\Scripts\activate.bat" >nul 2>&1
if not exist "%CONDA_PATH%\envs\edge-tts-env" goto CHECK_VENV_AFTER_CONDA
call conda activate edge-tts-env >nul 2>&1
set "ENV_FOUND=1"
goto CHECK_PYTHON
:CHECK_VENV_AFTER_CONDA
echo [INFO] Conda есть, но окружение 'edge-tts-env' не найдено.
echo [INFO] Ищем локальное venv...
goto CHECK_VENV
:CHECK_VENV
echo [INFO] Ищем локальное окружение Python (venv)...
echo [INFO] Папка поиска: %SCRIPT_DIR%
if exist "%SCRIPT_DIR%.venv\Scripts\activate.bat" goto ACTIVATE_DOT_VENV
if exist "%SCRIPT_DIR%venv\Scripts\activate.bat"  goto ACTIVATE_VENV
echo [ВНИМАНИЕ] Не найдено ни .venv ни venv в папке: %SCRIPT_DIR%
goto ERROR_NO_ENV
:ACTIVATE_DOT_VENV
echo [INFO] Найдено окружение .venv. Активируем...
call "%SCRIPT_DIR%.venv\Scripts\activate.bat"
set "ENV_FOUND=1"
goto CHECK_PYTHON
:ACTIVATE_VENV
echo [INFO] Найдено окружение venv. Активируем...
call "%SCRIPT_DIR%venv\Scripts\activate.bat"
set "ENV_FOUND=1"
goto CHECK_PYTHON
:CHECK_PYTHON
echo.
where python >nul 2>nul
if %errorlevel% neq 0 goto ERROR_NO_PYTHON
echo [INFO] Используется Python:
where python
python --version
echo.
goto CHECK_SCRIPT
:CHECK_SCRIPT
if exist "%SCRIPT_DIR%edge_tts_webui.py" goto LAUNCH_SERVER
echo [ОШИБКА] Файл 'edge_tts_webui.py' не найден!
echo Текущая папка: %SCRIPT_DIR%
echo Убедись, что run.bat лежит в одной папке со скриптом Gradio.
echo.
pause
exit /b
:LAUNCH_SERVER
echo [INFO] Все проверки пройдены успешно.
echo [INFO] Запуск локального сервера Gradio...
echo.
python "%SCRIPT_DIR%edge_tts_webui.py"
if %errorlevel% neq 0 goto ERROR_CRASH
exit
:ERROR_NO_ENV
echo.
echo [ОШИБКА] Виртуальное окружение не найдено!
echo.
echo   Искали в папке: %SCRIPT_DIR%
echo   Не обнаружено ни одного из окружений:
echo     - Conda: edge-tts-env
echo     - Локальное: .venv или venv
echo.
echo   Пожалуйста, сначала запустите install.bat
echo.
pause
exit /b
:ERROR_NO_PYTHON
echo.
echo [ОШИБКА] Python не найден!
echo Запустите install.bat или установите Python вручную.
echo.
pause
exit /b
:ERROR_CRASH
echo.
echo [КРИТИЧЕСКАЯ ОШИБКА] Скрипт завершился с кодом ошибки %errorlevel%
echo Возможно, повреждено окружение или не хватает библиотек.
echo Попробуйте переустановить окружение через install.bat
echo.
pause
exit /b