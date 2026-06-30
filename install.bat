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

set "CONDA_AVAILABLE=0"
if exist "%CONDA_PATH%" set "CONDA_AVAILABLE=1"

echo   Выберите способ создания окружения:
echo.
if "!CONDA_AVAILABLE!"=="1" goto PRINT_CONDA_FOUND
goto PRINT_CONDA_MISSING

:PRINT_CONDA_FOUND
echo   [1] Conda  (найдена: %CONDA_PATH%)
goto PRINT_MENU_REST

:PRINT_CONDA_MISSING
echo   [1] Conda  (не найдена -- выбор недоступен)
goto PRINT_MENU_REST

:PRINT_MENU_REST
echo   [2] Python venv  (стандартное виртуальное окружение)
echo   [0] Отмена
echo.

:MENU_LOOP
set "menu_choice="
set /p menu_choice="Ваш выбор (0-2): "

if "!menu_choice!"=="0" goto CANCELLED
if "!menu_choice!"=="2" goto VENV_FLOW
if "!menu_choice!"=="1" (
    if "!CONDA_AVAILABLE!"=="0" (
        echo [ОШИБКА] Conda не найдена. Установите Miniconda/Anaconda или выберите [2].
        goto MENU_LOOP
    )
    goto CONDA_FLOW
)

echo [ВНИМАНИЕ] Введите 0, 1 или 2.
goto MENU_LOOP


:CONDA_FLOW
echo.
echo [INFO] Найдена Conda по адресу: %CONDA_PATH%
echo [INFO] Подключаем базовые скрипты...
call "%CONDA_PATH%\Scripts\activate.bat" >nul 2>&1

where conda >nul 2>&1
if %errorlevel% neq 0 (
    echo [ОШИБКА] Conda найдена в папке, но команда 'conda' недоступна.
    echo Возможно, установка Conda повреждена.
    pause
    exit /b
)

set "CONDA_PY_VER=3.10"

if not exist "%CONDA_PATH%\envs\edge-tts-env" (
    echo [INFO] Создаём новое окружение Conda 'edge-tts-env' [Python %CONDA_PY_VER%]...
    call conda create -n edge-tts-env python=%CONDA_PY_VER% -y
    if !errorlevel! neq 0 (
        echo [ОШИБКА] Не удалось создать окружение Conda.
        pause
        exit /b
    )
    echo [INFO] Активируем окружение...
    call conda activate edge-tts-env
    goto INSTALL_PACKAGES
) else (
    set "REAL_CONDA_VER=неизвестно"
    if exist "%CONDA_PATH%\envs\edge-tts-env\python.exe" (
        for /f "tokens=2" %%v in ('"%CONDA_PATH%\envs\edge-tts-env\python.exe" --version 2^>nul') do set "REAL_CONDA_VER=%%v"
    )
    echo [INFO] Окружение 'edge-tts-env' уже существует [Python !REAL_CONDA_VER!].
    echo [INFO] Активируем окружение...
    call conda activate edge-tts-env

    echo.
    set "reinstall="
    set /p reinstall="Переустановить или обновить библиотеки через pip? (Y/N): "
    if /i "!reinstall!"=="Y" goto INSTALL_PACKAGES
    if /i "!reinstall!"=="YES" goto INSTALL_PACKAGES
    goto FINISH
)


:VENV_FLOW
echo.
echo [INFO] Переключаемся на стандартный Python venv...
echo.

if exist ".venv" (
    echo [INFO] Папка .venv уже существует. Активируем...
    call ".\.venv\Scripts\activate.bat"
    if !errorlevel! neq 0 (
        echo [ОШИБКА] Не удалось активировать существующее окружение .venv.
        pause
        exit /b
    )
    echo.
    set "reinstall="
    set /p reinstall="Переустановить или обновить библиотеки через pip? (Y/N): "
    if /i "!reinstall!"=="Y" goto INSTALL_PACKAGES
    if /i "!reinstall!"=="YES" goto INSTALL_PACKAGES
    goto FINISH
)

echo [INFO] Сканируем систему на наличие установленных версий Python...
set count=0

for /f "delims=" %%i in ('where python 2^>nul') do (
    set /a count+=1
    set "py_path_!count!=%%i"
    for /f "tokens=2" %%v in ('"%%i" --version 2^>nul') do (
        set "py_ver_!count!=%%v"
    )
)

if !count! == 0 (
    echo [ОШИБКА] Python не найден в системе!
    echo Установи Python 3.10+ с флагом "Add Python to PATH", либо поставь Miniconda.
    echo.
    pause
    exit /b
)

echo.
echo Найдено интерпретаторов Python: !count!
echo -------------------------------------------------------
for /l %%x in (1,1,!count!) do (
    echo   [%%x] Python !py_ver_%%x!  --  !py_path_%%x!
)
echo   [0] Отмена
echo -------------------------------------------------------
echo.

:CHOOSE_LOOP
set "user_choice="
set /p user_choice="Выберите номер версии Python (1-!count!) или 0 для отмены: "

if "!user_choice!"=="0" goto CANCELLED

echo !user_choice!| findstr /r "^[0-9][0-9]*$" >nul 2>&1
if !errorlevel! neq 0 (
    echo [ВНИМАНИЕ] Введите число от 0 до !count!.
    goto CHOOSE_LOOP
)
if !user_choice! LSS 1 goto CHOOSE_LOOP
if !user_choice! GTR !count! goto CHOOSE_LOOP

call set "CHOSEN_PYTHON=%%py_path_%user_choice%%%"
call set "SELECTED_VERSION=%%py_ver_%user_choice%%%"

echo.
echo [INFO] Выбран: Python !SELECTED_VERSION! — !CHOSEN_PYTHON!
echo [INFO] Создаём виртуальное окружение в папке .venv...

"!CHOSEN_PYTHON!" -m venv .venv
if !errorlevel! neq 0 (
    echo [ОШИБКА] Не удалось создать виртуальное окружение.
    pause
    exit /b
)

echo [INFO] Активируем окружение .venv...
call ".\.venv\Scripts\activate.bat"
if !errorlevel! neq 0 (
    echo [ОШИБКА] Не удалось активировать окружение .venv после создания.
    pause
    exit /b
)
goto INSTALL_PACKAGES


:INSTALL_PACKAGES
echo.
echo [INFO] Установка и обновление зависимостей...
echo.

python -m pip install --upgrade pip
if !errorlevel! neq 0 (
    echo [ПРЕДУПРЕЖДЕНИЕ] Не удалось обновить pip. Продолжаем...
)

if exist "requirements.txt" (
    echo [INFO] Устанавливаем из requirements.txt...
    pip install -r requirements.txt
) else (
    echo [ВНИМАНИЕ] Файл requirements.txt не найден.
    echo [INFO] Устанавливаю базовый набор: edge-tts gradio...
    pip install edge-tts gradio
)

if !errorlevel! neq 0 (
    echo.
    echo [ОШИБКА] Сбой при установке библиотек.
    echo Проверь подключение к интернету или права доступа к папке.
    pause
    exit /b
)
goto FINISH


:FINISH
echo.
echo ==================================================
echo   Установка завершена! Окружение готово к работе.
echo   Запусти проект через run.bat
echo ==================================================
echo.
pause
exit /b


:CANCELLED
echo.
echo [INFO] Установка отменена пользователем.
echo.
pause
exit /b