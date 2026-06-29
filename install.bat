@echo off
setlocal enabledelayedexpansion
chcp 65001 > nul
title Установка Edge TTS Studio

color 06

echo ==================================================
echo            Автоматическая установка и
echo        настройка окружения для Edge TTS  
echo ==================================================
echo.

set CONDA_PATH=%USERPROFILE%\miniconda3
if not exist "%CONDA_PATH%" set CONDA_PATH=%USERPROFILE%\anaconda3

if exist "%CONDA_PATH%" goto CONDA_FLOW
goto VENV_PROMPT


:CONDA_FLOW
echo [INFO] Найдена Conda по адресу: %CONDA_PATH%
echo [INFO] Подключаем базовые скрипты...
call "%CONDA_PATH%\Scripts\activate.bat" >nul 2>&1

set "CONDA_PY_VER=3.10"

if not exist "%CONDA_PATH%\envs\edge-tts-env" (
    echo [INFO] Создаем новое окружение Conda 'edge-tts-env' [Python %CONDA_PY_VER%]...
    call conda create -n edge-tts-env python=%CONDA_PY_VER% -y
    echo [INFO] Активируем окружение...
    call conda activate edge-tts-env
    goto INSTALL_PACKAGES
) else (
    set "REAL_CONDA_VER=неизвестно"
    if exist "%CONDA_PATH%\envs\edge-tts-env\python.exe" (
        for /f "tokens=2" %%v in ('"%CONDA_PATH%\envs\edge-tts-env\python.exe" --version 2^>nul') do set "REAL_CONDA_VER=%%v"
    )
    echo [INFO] Окружение Conda 'edge-tts-env' уже создано [Python !REAL_CONDA_VER!].
    echo [INFO] Активируем окружение...
    call conda activate edge-tts-env
    
    echo.
    set "reinstall="
    set /p reinstall="Хотите переустановить или обновить библиотеки через pip? (Y/N): "
    if /i "!reinstall!"=="Y" goto INSTALL_PACKAGES
    if /i "!reinstall!"=="YES" goto INSTALL_PACKAGES
    goto FINISH
)


:VENV_PROMPT
echo [ВНИМАНИЕ] Сервис Conda не найден в системе.
echo.
set "answer="
set /p answer="У вас нету сервиса Конда, хотите ли вы вместо конды создать обычное виртуальное окружение? (Y/N): "

if /i "%answer%"=="Y" goto VENV_FLOW
if /i "%answer%"=="YES" goto VENV_FLOW

echo.
echo [INFO] Установка отменена пользователем.
pause
exit /b


:VENV_FLOW
echo.
echo [INFO] Переключаемся на стандартный Python venv...
echo.

if exist ".venv" (
    echo [INFO] Локальная папка виртуального окружения .venv уже существует.
    echo [INFO] Активируем окружение .venv...
    call ".\.venv\Scripts\activate.bat"
    
    echo.
    set "reinstall="
    set /p reinstall="Хотите переустановить или обновить библиотеки через pip? (Y/N): "
    if /i "!reinstall!"=="Y" goto INSTALL_PACKAGES
    if /i "!reinstall!"=="YES" goto INSTALL_PACKAGES
    goto FINISH
)

echo [INFO] Сканируем систему на наличие установленных версий Python...
set count=0

for /f "delims=" %%i in ('where python 2^>nul') do (
    for /f "tokens=2" %%v in ('"%%i" --version 2^>nul') do (
        set /a count+=1
        set "py_path[!count!]=%%i"
        set "py_ver[!count!]=%%v"
    )
)

if !count! == 0 (
    echo [ОШИБКА] Рабочий Python не найден в твоей системе!
    echo Установи стандартный Python (желательно версии 3.10 или новее) и обязательно 
    echo отметь галочку "Add Python to PATH" при установке, либо поставь Miniconda.
    echo.
    pause
    exit /b
)

echo.
echo Найдено доступных интерпретаторов Python: !count!
echo --------------------------------------------------------------------------------
for /l %%x in (1, 1, !count!) do (
    echo   [%%x] Python !py_ver[%%x]!  --  ^(!py_path[%%x]!^)
)
echo --------------------------------------------------------------------------------
echo.

:CHOOSE_LOOP
set "user_choice="
set /p user_choice="Выберите номер нужной версии Python для создания .venv (1-!count!): "

if not defined user_choice goto CHOOSE_LOOP
if !user_choice! LSS 1 goto CHOOSE_LOOP
if !user_choice! GTR !count! goto CHOOSE_LOOP

for /f "delims=" %%a in ("!user_choice!") do (
    set "CHOSEN_PYTHON=!py_path[%%a]!"
    set "SELECTED_VERSION=!py_ver[%%a]!"
)

echo.
echo [INFO] Выбран для установки: Python !SELECTED_VERSION!

echo [INFO] Создаем локальное виртуальное окружение в папке .venv...
echo Используется интерпретатор: "!CHOSEN_PYTHON!"
"!CHOSEN_PYTHON!" -m venv .venv
if %errorlevel% neq 0 (
    echo [ОШИБКА] Не удалось создать виртуальное окружение через выбранный Python.
    pause
    exit /b
)

echo [INFO] Активируем окружение .venv...
call ".\.venv\Scripts\activate.bat"
goto INSTALL_PACKAGES


:INSTALL_PACKAGES
echo.
echo [INFO] Установка и обновление необходимых зависимостей...
echo.

python -m pip install --upgrade pip

if exist "requirements.txt" (
    echo [INFO] Ставим библиотеки из файла requirements.txt...
    pip install -r requirements.txt
) else (
    echo [ВНИМАНИЕ] Файл requirements.txt не найден.
    echo [INFO] Ставлю базовый набор пакетов напрямую...
    pip install edge-tts gradio
)

if %errorlevel% neq 0 (
    echo.
    echo [ОШИБКА] Произошел сбой при установке библиотек через pip.
    echo Проверь подключение к интернету или права доступа к папке.
    pause
    exit /b
)
goto FINISH


:FINISH
echo.
echo ==================================================
echo   Установка завершена! Окружение полностью готово.  
echo   Теперь ты можешь запустить проект через run.bat  
echo ==================================================
echo.
pause
exit /b