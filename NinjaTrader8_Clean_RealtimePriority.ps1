# Function to write log entries
function Out-LogEntry([string]$Message) {
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -FilePath $LogFile -Append
}

$userName = $env:USERNAME
$LogFile = "C:\Users\$userName\AlgoBox_NEW_Clean_RealtimePriority_Startup.txt"

# Remove and recreate directories
$directories = @(
    "cache",
    "db\cache",
    "db\day",
    "db\minute",
    "db\tick",
    "tmp",
    "trace",
    "log"
)

foreach ($dir in $directories) {
    Out-LogEntry "Removing directory: $dir"
    Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
    Out-LogEntry "Creating directory: $dir"
    New-Item -Path $dir -ItemType Directory -Force | Out-Null
}

# Define the process path
$ProcessPath = "C:\Program Files\NinjaTrader 8\bin\NinjaTrader.exe"

# Launch the NinjaTrader application
Out-LogEntry "Starting NinjaTrader application"
$Process = Start-Process -FilePath $ProcessPath -PassThru

# Define the C# code block compatible with .NET Framework 4.8
$Code = @'
using System;
using System.Runtime.InteropServices;

namespace PInvoke.Win32 {
    public static class ProcessApi {
        [DllImport("kernel32.dll", SetLastError=true)]
        public static extern bool SetPriorityClass(IntPtr handle, uint priorityClass);
    }

    public static class TokenApi {
        [DllImport("advapi32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool OpenProcessToken(IntPtr ProcessHandle,
            UInt32 DesiredAccess, out IntPtr TokenHandle);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool CloseHandle(IntPtr hObject);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool LookupPrivilegeValue(string lpSystemName, string lpName, ref LUID lpLuid);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges, 
            ref TOKEN_PRIVILEGES NewState, uint BufferLengthInBytes, 
            ref TOKEN_PRIVILEGES PreviousState, out uint ReturnLengthInBytes);

        [StructLayout(LayoutKind.Sequential)]
        public struct TOKEN_PRIVILEGES {
            public UInt32 PrivilegeCount;
            [MarshalAs(UnmanagedType.ByValArray, SizeConst = 1)] 
            public LUID_AND_ATTRIBUTES[] Privileges;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct LUID_AND_ATTRIBUTES {
            public LUID Luid;
            public UInt32 Attributes;
        }

        public struct LUID {
            public uint LowPart;
            public int HighPart;
        }

        // Constants
        public const UInt32 SE_PRIVILEGE_ENABLED = 0x00000002;
        public const string SE_INCREASE_BASE_PRIORITY_PRIVILEGE = "SeIncreaseBasePriorityPrivilege";
        public const UInt32 TOKEN_ADJUST_PRIVILEGES = 0x0020;
        public const UInt32 TOKEN_QUERY = 0x0008;
    }
}
'@

# Add the C# code as a new type definition to the PowerShell session
Add-Type -TypeDefinition $Code -Language CSharp

# Get the handle (identifier) of the process
$Handle = $Process.Handle
Out-LogEntry "Process handle: $Handle"

# Obtain necessary privileges
try {
    Out-LogEntry "Attempting to open process token"
    $TokenHandle = [IntPtr]::Zero
    $Result = [PInvoke.Win32.TokenApi]::OpenProcessToken($Handle, [PInvoke.Win32.TokenApi]::TOKEN_ADJUST_PRIVILEGES -bor [PInvoke.Win32.TokenApi]::TOKEN_QUERY, [ref] $TokenHandle)

    if (!$Result) {
        $ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Out-LogEntry "Failed to open process token. Error code: $ErrorCode"
        throw New-Object System.ComponentModel.Win32Exception($ErrorCode)
    }

    Out-LogEntry "Process token opened successfully"

    $Luid = New-Object PInvoke.Win32.TokenApi+LUID
    $Result = [PInvoke.Win32.TokenApi]::LookupPrivilegeValue([NullString]::Value, [PInvoke.Win32.TokenApi]::SE_INCREASE_BASE_PRIORITY_PRIVILEGE, [ref] $Luid)

    if (!$Result) {
        $ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Out-LogEntry "Failed to locate privilege. Error code: $ErrorCode"
        throw New-Object System.ComponentModel.Win32Exception($ErrorCode)
    }

    Out-LogEntry "Privilege located successfully"

    $TokenPrivileges = New-Object PInvoke.Win32.TokenApi+TOKEN_PRIVILEGES
    $TokenPrivileges.PrivilegeCount = 1
    $TokenPrivileges.Privileges = @(New-Object PInvoke.Win32.TokenApi+LUID_AND_ATTRIBUTES)
    $TokenPrivileges.Privileges[0].Luid = $Luid
    $TokenPrivileges.Privileges[0].Attributes = [PInvoke.Win32.TokenApi]::SE_PRIVILEGE_ENABLED

    $PreviousState = New-Object PInvoke.Win32.TokenApi+TOKEN_PRIVILEGES
    $ReturnLength = 0

    $Result = [PInvoke.Win32.TokenApi]::AdjustTokenPrivileges($TokenHandle, $false, [ref] $TokenPrivileges, [System.Runtime.InteropServices.Marshal]::SizeOf($PreviousState), [ref] $PreviousState, [ref] $ReturnLength)

    if (!$Result) {
        $ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Out-LogEntry "Failed to adjust token privileges. Error code: $ErrorCode"
        throw New-Object System.ComponentModel.Win32Exception($ErrorCode)
    }

    Out-LogEntry "Token privileges adjusted successfully"
}
catch {
    Out-LogEntry "An error occurred while adjusting token privileges: $_"
}
finally {
    if ($TokenHandle -ne [IntPtr]::Zero) {
        [PInvoke.Win32.TokenApi]::CloseHandle($TokenHandle)
    }
    Out-LogEntry "Privilege adjustment completed"
}

# Set the priority to Realtime
Out-LogEntry "Attempting to set Realtime priority"
$Result = [PInvoke.Win32.ProcessApi]::SetPriorityClass($Handle, 0x00000100)

if ($Result) {
    Out-LogEntry "Realtime priority set successfully"
}
else {
    $ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    Out-LogEntry "Failed to set Realtime priority. Error code: $ErrorCode"
}