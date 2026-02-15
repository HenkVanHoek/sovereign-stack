@echo off
:: File: restore_files_from_a_given_backup.cmd
:: Part of the sovereign-stack project.
:: Utility to extract specific files from encrypted backups on Windows.
::
:: Version: 4.0.0
:: Reference: backup_stack.sh (v4.0)
::
:: Copyright (C) 2026 Henk van Hoek
::
:: This program is free software: you can redistribute it and/or modify
:: it under the terms of the GNU General Public License as published by
:: the Free Software Foundation, either version 3 of the License, or
:: (at your option) any later version.
::
:: This program is distributed in the hope that it will be useful,
:: but WITHOUT ANY WARRANTY; without even the implied warranty of
:: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
:: GNU General Public License for more details.
::
:: You should have received a copy of the GNU General Public License
:: along with this program.  If not, see https://www.gnu.org/licenses/.

setlocal enabledelayedexpansion

echo ===========================================================
echo Sovereign Stack: Windows File Recovery Utility
echo ===========================================================

:: 1. OpenSSL Path Discovery
set "OPENSSL_BIN=openssl"
where openssl >nul 2>nul
if %errorlevel% neq 0 (
if exist "C:\Program Files\Git\usr\bin\openssl.exe" (
set "OPENSSL_BIN=C:\Program Files\Git\usr\bin\openssl.exe"
) else if exist "C:\Program Files (x86)\Git\usr\bin\openssl.exe" (
set "OPENSSL_BIN=C:\Program Files (x86)\Git\usr\bin\openssl.exe"
) else (
echo [ERROR] OpenSSL not found in PATH or Git folder.
echo Please ensure Git for Windows is installed correctly.
pause
exit /b 1
)
)

:: 2. Input Collection
set /p "INPUT_FILE=Enter backup filename or drag & drop: "
:: Remove quotes from path input
set "BACKUP_FILE=%INPUT_FILE:"=%"

if not exist "%BACKUP_FILE%" (
echo [ERROR] Backup file not found: "%BACKUP_FILE%"
pause
exit /b 1
)

:: Ask which file to restore
echo.
echo Specify the file path to restore from the archive.
echo (Paths are relative to DOCKER_ROOT, e.g., docker-compose.yaml or .env)
set "TARGET_FILE=docker-compose.yaml"
set /p "USER_TARGET=Enter file to restore [default: docker-compose.yaml]: "
if not "!USER_TARGET!"=="" set "TARGET_FILE=!USER_TARGET!"

:: Privacy Note: Password input is visible in the terminal
set /p "BACKUP_PASS=Enter BACKUP_PASSWORD: "

:: 3. Process
echo.
echo [1/3] Decrypting archive...
"%OPENSSL_BIN%" enc -d -aes-256-cbc -salt -pbkdf2 -pass "pass:%BACKUP_PASS%" -in "%BACKUP_FILE%" -out "temp_archive.tar.gz"

if %errorlevel% neq 0 (
echo [ERROR] Decryption failed. Check your password.
if exist "temp_archive.tar.gz" del "temp_archive.tar.gz"
pause
exit /b 1
)

echo [2/3] Extracting "!TARGET_FILE!" to temporary folder...
if exist "temp_extract" rmdir /s /q "temp_extract"
mkdir "temp_extract"

:: Using Windows native tar to extract the specific target
tar -xvzf "temp_archive.tar.gz" -C "temp_extract" "!TARGET_FILE!"

if %errorlevel% neq 0 (
echo [ERROR] Could not find "!TARGET_FILE!" in the archive.
) else (
:: Determine output filename (preventing overwrite of existing local files)
set "OUT_FILE=!TARGET_FILE!"
:: Replace slashes and backslashes with underscores for a safe recovered filename
set "SAFE_OUT=!OUT_FILE:/=!"
set "SAFE_OUT=!SAFE_OUT:=!"

if exist "temp_extract\!TARGET_FILE!" (
    move /y "temp_extract\!TARGET_FILE!" "!SAFE_OUT!.recovered"
    echo [3/3] Success! File saved as: !SAFE_OUT!.recovered
) else (
    echo [ERROR] Extraction reported success, but file not found in temp_extract.
)


)

:: 4. Cleanup
if exist "temp_archive.tar.gz" del "temp_archive.tar.gz"
if exist "temp_extract" rmdir /s /q "temp_extract"

echo.
echo Done.
pause
