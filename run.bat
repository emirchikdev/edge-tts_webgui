@echo off
chcp 65001 > nul
title Запуск Edge TTS Studio

color 06

cd /d "%~dp0"

echo ==================================================
echo           Запуск Microsoft Edge TTS Studio         
echo ==================================================
echo.

set CONDA_PATH=%USERPROFILE%\miniconda3
if not exist "%CONDA_PATH%" set CONDA_PATH=%USERPROFILE%\anaconda3

if exist "%CONDA_PATH%" goto ACTIVATE_CONDA
goto CHECK_VENV

:ACTIVATE_CONDA
echo [INFO] Найдена Conda. Активируем окружение 'edge-tts-env'...
call "%CONDA_PATH%\Scripts\activate.bat" >nul 2>&1
call conda activate edge-tts-env >nul 2>&1
goto CHECK_PYTHON

:CHECK_VENV
echo [ВНИМАНИЕ] Conda не найдена. Ищем локальное окружение Python (venv)...
if exist ".\.venv\Scripts\activate.bat" goto ACTIVATE_DOT_VENV
if exist ".\venv\Scripts\activate.bat" goto ACTIVATE_VENV

echo [ВНИМАНИЕ] Локальные папки venv/.venv не обнаружены.
echo Пробуем запустить через глобальный системный Python...
goto CHECK_PYTHON

:ACTIVATE_DOT_VENV
echo [INFO] Найдено окружение в папке .venv. Активируем...
call ".\.venv\Scripts\activate.bat"
goto CHECK_PYTHON

:ACTIVATE_VENV
echo [INFO] Найдено окружение в папке venv. Активируем...
call ".\venv\Scripts\activate.bat"
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

:ERROR_NO_PYTHON
echo [ОШИБКА] Python не найден!
echo Он не активировался через Conda/venv и не установлен глобально в Windows.
echo Пожалуйста, запусти install.bat или установи Python вручную.
echo.
pause
exit /b

:CHECK_SCRIPT
if exist "edge_tts_webui.py" goto LAUNCH_SERVER

echo [ОШИБКА] Файл 'edge_tts_webui.py' не найден!
echo Текущая папка: %CD%
echo Убедись, что этот .bat файл лежит в одной папке со скриптом Gradio.
echo.
pause
exit /b

:LAUNCH_SERVER
echo [INFO] Все проверки пройдены успешно.
echo [INFO] Запуск локального сервера Gradio...
echo.

python edge_tts_webui.py
if %errorlevel% neq 0 goto ERROR_CRASH

exit

:ERROR_CRASH
echo.
echo [КРИТИЧЕСКАЯ ОШИБКА] Скрипт завершился с кодом ошибки %errorlevel%
echo Возможно, не установлены библиотеки edge-tts или gradio.
echo Попробуй выполнить в этом окне:
echo     pip install edge-tts gradio
echo.
pause
exit /b