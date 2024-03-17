@echo off
set "psScript=C:\Users\%USERNAME%\Documents\NinjaTrader 8\NinjaTrader8_Clean_RealtimePriority.ps1"
set "logFile=C:\Users\%USERNAME%\AlgoBox_NEW_Clean_RealtimePriority_Startup.txt"

echo Launching NinjaTrader with Realtime Priority...

start /wait "" PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%psScript%\"' -Verb RunAs}"

echo NinjaTrader launched with Realtime Priority. Check the log file for details: "%logFile%"