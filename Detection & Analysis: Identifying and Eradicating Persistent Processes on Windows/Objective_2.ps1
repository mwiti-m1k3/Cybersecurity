# ====================================================================================
# USER INPUT SECTION: CHANGE THIS VALUE BEFORE RUNNING THE SCRIPT
# Enter the Process ID (PID) to inspect (e.g., 1234)
# Example: To find a Chrome PID, open Task Manager, go to the Details tab, and look for 'chrome.exe'.
# ====================================================================================
[int]$PID = 24988  # <--- REPLACE 1234 WITH A LIVE CHROME PID

# --- 1. Validate and Retrieve Process Details (Path, Owner) ---

if (-not $PID) {
    Write-Error "A Process ID (PID) must be provided."
    exit
}

# Get core process details
$processDetails = Get-WmiObject -Class Win32_Process -Filter "ProcessId = $PID" | Select-Object -First 1

if (-not $processDetails) {
    Write-Error "No process found with Process ID $($PID)."
    exit
}

# Identify the executable name instead of a service name
$ProcessName = $processDetails.Name
$Path = $processDetails.ExecutablePath
$Owner = ($processDetails.GetOwner()).User

# --- 2. Get Network Connections (Local and Foreign Address) ---

# Netstat parsing logic - collecting only the necessary columns
$netstatParsed = (netstat -ano) | Select-String -Pattern "TCP|UDP" | ForEach-Object {
    $parts = $_.Line.Trim() -split '\s+'
    if ($parts.Count -ge 5) {
        [PSCustomObject]@{
            LocalAddress   = $parts[1]
            ForeignAddress = $parts[2]
            ProcessId      = [int]$parts[-1]
        }
    }
}

$netstatMatches = $netstatParsed | Where-Object {$_.ProcessId -eq $PID}

# --- 3. Flatten and Output Data ---

$outputData = @()

if ($netstatMatches) {
    # Create one row per network connection
    $netstatMatches | ForEach-Object {
        $outputData += [PSCustomObject]@{
            ProcessName       = $ProcessName
            PID               = $PID
            ExecutablePath    = $Path
            StartedBy         = $Owner
            LocalAddress      = $_.LocalAddress
            ForeignAddress    = $_.ForeignAddress
        }
    }
} else {
    # Create a single row if no connections are found
    $outputData += [PSCustomObject]@{
        ProcessName       = $ProcessName
        PID               = $PID
        ExecutablePath    = $Path
        StartedBy         = $Owner
        LocalAddress      = "N/A (No active connection)"
        ForeignAddress    = "N/A (No active connection)"
    }
}

# Final output in a table format
$outputData | Format-Table -AutoSize