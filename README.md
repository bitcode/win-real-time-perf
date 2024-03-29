# NinjaTrader 8 Realtime Priority and Cleanup Script

This repository contains a batch script (`AlgoBox_NEW_Clean_RealtimePriority_Startup.bat`) and a PowerShell script (`NinjaTrader8_Clean_RealtimePriority.ps1`) that automate the process of setting the NinjaTrader 8 application to run with Realtime CPU priority and perform some cleanup tasks on startup.

## Usage

1. Download the ZIP file from the GitHub repository.
2. Extract the `AlgoBox_NEW_Clean_RealtimePriority_Startup.bat` and `NinjaTrader8_Clean_RealtimePriority.ps1` files to the `C:\Users\<user>\Documents\NinjaTrader 8` directory.
3. Right-click on the `AlgoBox_NEW_Clean_RealtimePriority_Startup.bat` file and select "Run As Administrator".

The batch script will perform the following actions:
- Display a message indicating that NinjaTrader is being launched with Realtime priority.
- Launch a new console window for the PowerShell process and wait for it to complete.
- Display a message indicating that NinjaTrader has been launched with Realtime priority and provide the location of the log file.
- Automatically close the console window.

The PowerShell script will perform the following actions:
- Remove and recreate several directories related to NinjaTrader 8 (cache, db/cache, db/day, db/minute, db/tick, tmp, trace, log).
- Start the NinjaTrader 8 application.
- Set the CPU priority of the NinjaTrader process to Realtime.

## Warnings and Disclaimer

- This script modifies the CPU priority of the NinjaTrader process to Realtime. Setting a process to Realtime priority can potentially impact the stability and responsiveness of your system. Use it with caution and ensure that your system has sufficient resources to handle the increased priority.
- The script performs cleanup tasks by removing and recreating certain directories. Make sure you have backups of any important data before running the script.
- The script requires Administrator privileges to run. Ensure that you have the necessary permissions and trust the source of the script before executing it.
- I am not responsible for any damages or issues caused by using this script. Use it at your own risk.

## How It Works

The batch script (`AlgoBox_NEW_Clean_RealtimePriority_Startup.bat`) performs the following steps:

1. It displays a message indicating that NinjaTrader is being launched with Realtime priority.
2. It uses the `start` command with the `/wait` option to launch a new console window for the PowerShell process and wait for it to complete.
3. It displays a message indicating that NinjaTrader has been launched with Realtime priority and provides the location of the log file.
4. It automatically closes the console window.

The PowerShell script (`NinjaTrader8_Clean_RealtimePriority.ps1`) does the following:

1. It removes and recreates several directories related to NinjaTrader 8 (cache, db/cache, db/day, db/minute, db/tick, tmp, trace, log) to clean up any temporary or cached files.
2. It starts the NinjaTrader 8 application using the specified path.
3. It imports the necessary Win32 API functions to interact with process tokens and privileges.
4. It retrieves the process object based on the provided process path.
5. It obtains the necessary privileges to adjust the process priority.
6. It sets the CPU priority of the NinjaTrader process to Realtime using the `SetPriorityClass` function from the Win32 API.
7. It logs the execution steps and any errors encountered during the process.

The script aims to solve the problem of easily setting a process to Realtime priority on startup. It provides a streamlined way to automate the process and perform cleanup tasks for NinjaTrader 8.

## Contributing

If you have any suggestions, improvements, or bug fixes, feel free to open an issue or submit a pull request. Contributions are welcome!

## License

This script is released under the [MIT License](LICENSE).