# Declare a parameter named $ProcessName to accept the name of the process as input
param(
    [string]$ProcessName
)

# Define a C# code block as a string
$Code = @'
using System;
using System.Runtime.InteropServices;

namespace PInvoke.Win32 {
    public static class ProcessApi {
        // Import the SetPriorityClass function from the Windows API (kernel32.dll)
        // This function is used to set the priority class of a process
        [DllImport("kernel32.dll", SetLastError=true)]
        public static extern bool SetPriorityClass(IntPtr handle, uint priorityClass);
    }
}
'@

# Import necessary Win32 API functions
Add-Type @'
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
        public const UInt32 STANDARD_RIGHTS_REQUIRED = 0x000F0000;
        public const UInt32 TOKEN_ASSIGN_PRIMARY = 0x0001;
        public const UInt32 TOKEN_DUPLICATE = 0x0002;
        public const UInt32 TOKEN_IMPERSONATE = 0x0004;
        public const UInt32 TOKEN_QUERY = 0x0008;
        public const UInt32 TOKEN_QUERY_SOURCE = 0x0010;
        public const UInt32 TOKEN_ADJUST_PRIVILEGES = 0x0020;
        public const UInt32 TOKEN_ADJUST_GROUPS = 0x0040;
        public const UInt32 TOKEN_ADJUST_DEFAULT = 0x0080;
        public const UInt32 TOKEN_ADJUST_SESSIONID = 0x0100;
        public const UInt32 TOKEN_ALL_ACCESS = (STANDARD_RIGHTS_REQUIRED |
            TOKEN_ASSIGN_PRIMARY | TOKEN_DUPLICATE |
            TOKEN_IMPERSONATE | TOKEN_QUERY |
            TOKEN_QUERY_SOURCE | TOKEN_ADJUST_PRIVILEGES |
            TOKEN_ADJUST_GROUPS | TOKEN_ADJUST_DEFAULT |
            TOKEN_ADJUST_SESSIONID); 
    }
}
'@

# Get the process based on the name 
$Process = Get-Process -Name $ProcessName

# Get the handle of the process
$Handle = $Process.Handle

# Obtain necessary privileges
try {
    $TokenHandle = IntPtr.Zero
    $Result = [PInvoke.Win32.TokenApi]::OpenProcessToken($Handle, [PInvoke.Win32.TokenApi]::TOKEN_ADJUST_PRIVILEGES, [ref] $TokenHandle)

    if (!$Result) {
        throw New-Object System.ComponentModel.Win32Exception([Marshal]::GetLastWin32Error())
    }

    $Luid = New-Object PInvoke.Win32.TokenApi+LUID
    $Result = [PInvoke.Win32.TokenApi]::LookupPrivilegeValue([IntPtr]::Zero, [PInvoke.Win32.TokenApi]::SE_INCREASE_BASE_PRIORITY_PRIVILEGE, [ref] $Luid)

    if (!$Result) {
        throw New-Object System.ComponentModel.Win32Exception([Marshal]::GetLastWin32Error())
    }

    $TokenPrivileges = New-Object PInvoke.Win32.TokenApi+TOKEN_PRIVILEGES
    $TokenPrivileges.PrivilegeCount = 1
    $TokenPrivileges.Privileges = (New-Object PInvoke.Win32.TokenApi+LUID_AND_ATTRIBUTES) -as [PInvoke.Win32.TokenApi+LUID_AND_ATTRIBUTES[]]
    $TokenPrivileges.Privileges[0].Luid = $Luid
    $TokenPrivileges.Privileges[0].Attributes = [PInvoke.Win32.TokenApi]::SE_PRIVILEGE_ENABLED

    $Result = [PInvoke.Win32.TokenApi]::AdjustTokenPrivileges($TokenHandle, $false, [ref] $TokenPrivileges, 0, [IntPtr]::Zero, [IntPtr]::Zero)

    if (!$Result) {
        throw New-Object System.ComponentModel.Win32Exception([Marshal]::GetLastWin32Error())
    }

}
finally {
    if ($TokenHandle -ne [IntPtr]::Zero) {
        [PInvoke.Win32.TokenApi]::CloseHandle($TokenHandle)
    }
}


# Set the priority to Realtime
[PInvoke.Win32.ProcessApi]::SetPriorityClass($Handle, 0x00000100) # Add the C# code as a new type definition to the PowerShell session
# This allows accessing the SetPriorityClass function from PowerShell
Add-Type -TypeDefinition $Code -Language CSharp

# Get the process object based on the provided process name
$Process = Get-Process -Name $ProcessName

# Get the handle (identifier) of the process
$Handle = $Process.Handle

# Call the SetPriorityClass function from the imported C# code
# Pass the process handle and the priority class value (0x00000100 represents Realtime priority)
# This sets the CPU priority of the specified process to Realtime
[PInvoke.Win32.ProcessApi]::SetPriorityClass($Handle, 0x00000100)

# Define a log file path
$LogFile = "C:\ProcessPriorityPowerShellLog.txt"

# Function to write log entries
function Out-LogEntry([string]$Message) {
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -FilePath $LogFile -Append
}

# Get the process based on the name 
$Process = Get-Process -Name $ProcessName

# Get the handle of the process
$Handle = $Process.Handle

# Obtain necessary privileges
try {
    Out-LogEntry "Attempting to open process token" 
    $TokenHandle = IntPtr.Zero
    $Result = [PInvoke.Win32.TokenApi]::OpenProcessToken($Handle, [PInvoke.Win32.TokenApi]::TOKEN_ADJUST_PRIVILEGES, [ref] $TokenHandle)

    if (!$Result) {
        $ErrorCode = [Marshal]::GetLastWin32Error()
        Out-LogEntry "Failed to open process token. Error code: $ErrorCode" 
        throw New-Object System.ComponentModel.Win32Exception($ErrorCode)
    }

    Out-LogEntry "Process token opened successfully"
    $Luid = New-Object PInvoke.Win32.TokenApi+LUID
    $Result = [PInvoke.Win32.TokenApi]::LookupPrivilegeValue([IntPtr]::Zero, [PInvoke.Win32.TokenApi]::SE_INCREASE_BASE_PRIORITY_PRIVILEGE, [ref] $Luid)

    if (!$Result) {
        $ErrorCode = [Marshal]::GetLastWin32Error()
        Out-LogEntry "Failed to locate privilege. Error code: $ErrorCode" 
        throw New-Object System.ComponentModel.Win32Exception($ErrorCode)
    }

    Out-LogEntry "Privilege located successfully"
    $TokenPrivileges = New-Object PInvoke.Win32.TokenApi+TOKEN_PRIVILEGES
    # ... (Rest of your privilege adjustment code) ...

    $Result = [PInvoke.Win32.TokenApi]::AdjustTokenPrivileges($TokenHandle, $false, [ref] $TokenPrivileges, 0, [IntPtr]::Zero, [IntPtr]::Zero)

    if (!$Result) {
        $ErrorCode = [Marshal]::GetLastWin32Error()
        Log-Message "Failed to adjust token privileges. Error code: $ErrorCode" 
        throw New-Object System.ComponentModel.Win32Exception($ErrorCode)
    }

    Out-LogEntry "Token privileges adjusted successfully" 
}
finally {
    if ($TokenHandle -ne [IntPtr]::Zero) {
        [PInvoke.Win32.TokenApi]::CloseHandle($TokenHandle)
    }
    Out-LogEntry "Privilege adjustment completed"
}

# Set the priority to Realtime
Out-LogEntry "Attempting to set Realtime priority"
[PInvoke.Win32.ProcessApi]::SetPriorityClass($Handle, 0x00000100) 
Out-LogEntry "Realtime priority set (if successful)"