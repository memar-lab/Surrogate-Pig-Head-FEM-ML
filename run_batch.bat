@echo off
REM ============================================================
REM  Batch mode for FEM-ML Surrogate.
REM
REM  Runs a prediction for every CSV file in the input folder.
REM  Execution runs in the background while displaying a loading bar.
REM ============================================================
setlocal enabledelayedexpansion
echo ===================================================
echo FEM-ML Surrogate Initialization Pipeline
echo Press Ctrl + C at any time to forcefully abort execution.
echo ===================================================
echo.

:INPUT_CONFIG
set "INPUT_PATH="
set /p "INPUT_PATH=Define path to CSV input folder (Leave blank for default: %~dp0BatchInputs, or type Q to quit): "
if /I "!INPUT_PATH!"=="Q" goto EXIT
if "!INPUT_PATH!"=="" (
    set "INPUT_PATH=%~dp0BatchInputs"
) else (
    REM Strip potential surrounding quotes from drag-and-drop actions
    set "INPUT_PATH=!INPUT_PATH:"=!"
)

:TYPE_CONFIG
echo.
echo Select Input Type:
echo [1] VelocityTrace
echo [2] AccelerationTrace
echo [3] PeakValues
echo [Q] Quit
set "TYPE_CHOICE="
set /p "TYPE_CHOICE=Enter selection (1-3, or Q): "
if /I "!TYPE_CHOICE!"=="Q" goto EXIT
if "!TYPE_CHOICE!"=="1" (set "TYPE=VelocityTrace") else if "!TYPE_CHOICE!"=="2" (set "TYPE=AccelerationTrace") else if "!TYPE_CHOICE!"=="3" (set "TYPE=PeakValues") else (goto TYPE_CONFIG)

:DIRECTION_CONFIG
echo.
echo Select Impact Direction:
echo [1] Axial
echo [2] Sagittal
echo [3] Coronal
echo [Q] Quit
set "DIR_CHOICE="
set /p "DIR_CHOICE=Enter selection (1-3, or Q): "
if /I "!DIR_CHOICE!"=="Q" goto EXIT
if "!DIR_CHOICE!"=="1" (set "DIRECTION=Axial") else if "!DIR_CHOICE!"=="2" (set "DIRECTION=Sagittal") else if "!DIR_CHOICE!"=="3" (set "DIRECTION=Coronal") else (goto DIRECTION_CONFIG)

:MODEL_CONFIG
echo.
echo Select Model Architecture:
echo [1] DNN
echo [2] Lasso
echo [3] Ridge
echo [4] Random Forest - Linear
echo [5] Random Forest - Curvature
echo [Q] Quit
set "MODEL_CHOICE="
set /p "MODEL_CHOICE=Enter selection (1-5, or Q): "
if /I "!MODEL_CHOICE!"=="Q" goto EXIT
if "!MODEL_CHOICE!"=="1" (set "MODEL=DNN") else if "!MODEL_CHOICE!"=="2" (set "MODEL=Lasso") else if "!MODEL_CHOICE!"=="3" (set "MODEL=Ridge") else if "!MODEL_CHOICE!"=="4" (set "MODEL=Random Forest - Linear") else if "!MODEL_CHOICE!"=="5" (set "MODEL=Random Forest - Curvature") else (goto MODEL_CONFIG)

:OUT_CONFIG
echo.
set "OUT_PATH="
set /p "OUT_PATH=Define results output folder (Leave blank for %~dp0Results, or type Q to quit): "
if /I "!OUT_PATH!"=="Q" goto EXIT
if "!OUT_PATH!"=="" (
    set "OUT_PATH=%~dp0Results"
) else (
    set "OUT_PATH=!OUT_PATH:"=!"
)

echo.
echo Executing FEM-ML Surrogate parameters:
echo ---------------------------------------------------
echo INPUT:     "!INPUT_PATH!"
echo TYPE:      !TYPE!
echo DIRECTION: !DIRECTION!
echo MODEL:     "!MODEL!"
echo OUT:       "!OUT_PATH!"
echo ---------------------------------------------------
echo.

REM The exe writes an integer percent (0-100) here as it processes files.
REM Clear any stale value left over from a previous run.
set "PROGRESS_FILE=!OUT_PATH!\batch_progress.txt"
if exist "!PROGRESS_FILE!" del /q "!PROGRESS_FILE!" >nul 2>&1

echo Working (first launch can take a few seconds to start)...
echo.

start "" /B "%~dp0FEMML_Surrogate.exe" --batch --input "!INPUT_PATH!" --type "!TYPE!" --direction "!DIRECTION!" --model "!MODEL!" --out "!OUT_PATH!" >nul 2>&1

REM Poll the progress file and print a new bar line only when the percent
REM changes. Do not stop until the run reports 100%% or the exe has actually
REM started and then exited - this keeps the window open for the whole run.
set "LASTPCT=-1"
set "STARTED="
set "STARTWAIT=0"
:LOADING_BAR
set "PCT="
if exist "!PROGRESS_FILE!" (
    set "STARTED=1"
    set /p PCT=<"!PROGRESS_FILE!"
)
if "!PCT!"=="" set "PCT=!LASTPCT!"
if "!PCT!"=="-1" set "PCT=0"
if not "!PCT!"=="!LASTPCT!" (
    set /a FILLED=PCT/5
    set "BAR="
    for /l %%i in (1,1,20) do (
        if %%i LEQ !FILLED! (set "BAR=!BAR!#") else (set "BAR=!BAR!-")
    )
    echo   Progress: [!BAR!] !PCT!%%
    set "LASTPCT=!PCT!"
)

REM Finished when the run reports 100%.
if "!PCT!"=="100" goto DONE

REM Otherwise keep going based on whether the exe is still running.
tasklist /FI "IMAGENAME eq FEMML_Surrogate.exe" 2>nul | find /I "FEMML_Surrogate.exe" >nul
if "!ERRORLEVEL!"=="0" (
    set "STARTED=1"
    timeout /t 1 /nobreak >nul
    goto LOADING_BAR
)

REM Exe is not in the task list. If it had already started, the run is done.
if defined STARTED goto DONE

REM It hasn't come up yet (still unpacking) - wait longer before giving up.
set /a STARTWAIT+=1
if !STARTWAIT! GEQ 30 (
    echo.
    echo Could not start FEMML_Surrogate.exe. Make sure the exe is next to this script.
    pause
    exit /b 1
)
timeout /t 1 /nobreak >nul
goto LOADING_BAR

:DONE
if not "!LASTPCT!"=="100" echo   Progress: [####################] 100%%
echo.
echo Complete.
pause
exit /b

:EXIT
echo.
echo Setup aborted by user.
pause
exit /b