# 1. Define the list of common, essential PROCESS NAMES (Executables) to be EXCLUDED.
# NOTE: This list now contains common *process names* instead of *service names*.
$commonProcessNames = @(
    "svchost",                   # Hosts many common Windows services
    "explorer",                  # Windows File Explorer and Desktop
    "dwm",                       # Desktop Window Manager
    "csrss",                     # Client Server Runtime Process
    "lsass",                     # Local Security Authority Process
    "smss",                      # Session Manager Subsystem
    "runtimebroker",             # Manages permissions for Windows Store apps
    "taskhostw",                 # Host Process for Windows Tasks
    "microsoft.photos",          # Windows Photos App (example user app)
    "chrome",                    # Google Chrome (example common app)
    "msedge",                    # Microsoft Edge (example common app)
    "powershell",                # PowerShell process
    "audiodg",                   # Windows Audio Device Graph Isolation
    "System",                    # The System process (PID 4)
    "services",                  # Services and Controller app
    "winlogon",                  # Windows Logon Application
    "SearchHost",                # Windows Search
    "SecurityHealthService"      # Windows Security Health Service
    # Add more common, known executable names (without the .exe) here.
)

# --- 1. Get ALL Running Processes ---
$allProcesses = Get-Process

# Parse netstat output into structured objects
$netstatParsed = (netstat -ano) | Select-String -Pattern "TCP|UDP" | ForEach-Object {
    $parts = $_.Line.Trim() -split '\s+'
    if ($parts.Count -ge 5) {
        [PSCustomObject]@{
            Protocol       = $parts[0]
            LocalAddress   = $parts[1]
            ForeignAddress = $parts[2]
            State          = if ($parts.Count -ge 5) {$parts[3]} else {""}
            ProcessId      = [int]$parts[-1]
        }
    }
}

# 2. Filter ALL running processes to exclude the common ones.
$uncommonRunningProcesses = $allProcesses | Where-Object {
    $BaseName = $_.ProcessName.ToLower() # Use the base name for filtering
    
    # Check if the process name is NOT in the exact exclusion list
    $BaseName -notin $commonProcessNames
}

$outputData = $uncommonRunningProcesses | ForEach-Object {
    $process = $_
    $processPID = $process.Id
    $processName = $process.ProcessName + ".exe"

    # Get all netstat entries matching this process's PID
    $netstatMatches = $netstatParsed | Where-Object {$_.ProcessId -eq $processPID}

    # If connections exist, create one row per connection
    if ($netstatMatches) {
        $netstatMatches | ForEach-Object {
            [PSCustomObject]@{
                ProcessName      = $processName
                PID              = $processPID
                LocalAddress     = $_.LocalAddress
                ForeignAddress   = $_.ForeignAddress
            }
        }
    }
    # If NO connections exist, create one row with "N/A" connection fields
    else {
        [PSCustomObject]@{
            ProcessName      = $processName
            PID              = $processPID
            LocalAddress     = "N/A (No active connection)"
            ForeignAddress   = "N/A (No active connection)"
        }
    }
}

# Final output in a table format, showing only UNCOMMON running processes.
$outputData | Format-Table -AutoSize