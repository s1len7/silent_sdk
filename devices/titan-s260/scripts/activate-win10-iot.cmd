@echo off
rem Double-click launcher (bypasses execution policy)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0activate-win10-iot.ps1" %*
