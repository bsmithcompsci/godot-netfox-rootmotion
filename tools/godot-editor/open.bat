@echo off

if not defined PROJECT_PATH (
    echo "PROJECT_PATH is not defined"
    pause
    exit /b 1
)

set VERSION=4.3-stable
set DOWNLOAD_URL=https://github.com/godotengine/godot-builds/releases/download/%VERSION%/Godot_v%VERSION%_win64.exe.zip
set UNZIP_DIR=tools\godot-editor

REM Create the target directory if it doesn't exist
if not exist %UNZIP_DIR% mkdir %UNZIP_DIR%

REM Check if the executable already exists
if not exist %UNZIP_DIR%\Godot_v%VERSION%_win64.exe (
    pushd %UNZIP_DIR%
    REM Download the Godot editor zip file
    curl -L -o godot-editor.zip %DOWNLOAD_URL%
	if errorlevel 1 (
		echo "Failed to download the Godot editor"
		pause
		exit /b 1
	)

    REM Unzip the downloaded file into the target directory
    powershell -Command "Expand-Archive -Path godot-editor.zip -DestinationPath ."
	if errorlevel 1 (
		echo "Failed to unzip the Godot editor"
		pause
		exit /b 1
	)

    REM Clean up the downloaded zip file
    del godot-editor.zip
    popd
)

REM Prompt the user to choose between console or regular executable
choice /C YN /M "Do you want to open the Godot Editor in Console Mode?"

REM Open the chosen executable
if errorlevel 2 (
    echo "Disable Console Mode..."
    start "" "%UNZIP_DIR%\Godot_v%VERSION%_win64.exe" --editor --path "%PROJECT_PATH%"
) else (
    echo "Enable Console Mode..."
    "%UNZIP_DIR%\Godot_v%VERSION%_win64_console.exe" -v -d --editor --path "%PROJECT_PATH%"
    if not errorlevel 0 pause
)

exit /b 0