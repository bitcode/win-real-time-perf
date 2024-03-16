SET LogFile=C:\AlgoBox_NEW_Clean_RealtimePriority_Startup.txt

REM Remove the "cache" directory and its contents, then recreate the directory
rd /s /q "cache" 2>> %LogFile%
md "cache" 2>> %LogFile%

REM Remove the "db\cache" directory and its contents, then recreate the directory
rd /s /q "db\cache" 2>> %LogFile%
md "db/cache" 2>> %LogFile%

REM Remove the "db\day" directory and its contents, then recreate the directory
rd /s /q "db\day" 2>> %LogFile%
md "db\day" 2>> %LogFile%

REM Remove the "db\minute" directory and its contents, then recreate the directory
rd /s /q "db\minute" 2>> %LogFile%
md "db\minute" 2>> %LogFile%

REM Remove the "db\tick" directory and its contents, then recreate the directory
rd /s /q "db\tick" 2>> %LogFile%
md "db\tick" 2>> %LogFile%

REM Remove the "tmp" directory and its contents, then recreate the directory
rd /s /q "tmp" 2>> %LogFile%
md "tmp" 2>> %LogFile%

REM Remove the "trace" directory and its contents, then recreate the directory
rd /s /q "trace" 2>> %LogFile%
md "trace" 2>> %LogFile%

REM Remove the "log" directory and its contents, then recreate the directory
rd /s /q "log" 2>> %LogFile%
md "log" 2>> %LogFile%

REM Start the NinjaTrader application
start "NT8" "C:\Program Files\NinjaTrader 8\bin\NinjaTrader.exe" 2>> %LogFile%

REM Call the PowerShell script to set the CPU priority of the NinjaTrader process to Realtime
REM -ExecutionPolicy Bypass: Allows the execution of the PowerShell script regardless of the current execution policy
REM -File "Set-RealtimePriority.ps1": Specifies the PowerShell script file to execute
REM -ProcessName "NinjaTrader": Passes the process name "NinjaTrader" as a parameter to the PowerShell script
powershell -ExecutionPolicy Bypass -File "Set-RealtimePriority.ps1" -ProcessName "NinjaTrader" 2>> %LogFile%