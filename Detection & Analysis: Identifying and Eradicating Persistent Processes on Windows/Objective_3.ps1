# ===========================================================================
# USER INPUT SECTION: CHANGE THIS VALUE BEFORE RUNNING THE SCRIPT
# Replace the placeholder path with the actual ExecutablePath you want to check.
# ===========================================================================
[string]$ExecutablePathToCheck = "C:\Windows\System32\SecurityHealthSystray.exe" # <--- INSERT YOUR PATH HERE

function Get-StartupStatus {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ExecutablePath
    )

    $FileName = Split-Path -Path $ExecutablePath -Leaf
    $StartupStatus = "No (Manual or Scheduled Task)" # Default status

    # Define persistence locations
    $StartupKeys = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    )
    $StartupFolders = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
    )

    # 1. Check Registry Run Keys
    foreach ($key in $StartupKeys) {
        try {
            $RegEntries = Get-ItemProperty -Path $key -ErrorAction Stop | Select-Object *
            
            # Check if any value data contains the full path or just the filename
            $match = $RegEntries.PSObject.Properties | Where-Object { 
                # Use -clike (case-insensitive like) for robustness
                $_.Value -clike "*$ExecutablePath*" -or $_.Value -clike "*$FileName*"
            }

            if ($match) {
                return "Yes (Registry: $($key.Split(':')[-1]))"
            }
        }
        catch {
            # Key not found or access denied, safely continue
        }
    }

    # 2. Check Startup Folders
    foreach ($folder in $StartupFolders) {
        $StartupFiles = Get-ChildItem -Path $folder -Recurse -ErrorAction SilentlyContinue | Where-Object { 
            ($_.Name -clike "*$FileName*") -and ($_.PSIsContainer -eq $false) 
        }
        
        if ($StartupFiles) {
            return "Yes (Startup Folder)"
        }
    }
    
    # 3. Check for associated Windows Service with Automatic start type
    try {
        $serviceMatch = Get-WmiObject -Class Win32_Service | Where-Object { 
            $_.PathName -clike "*$ExecutablePath*" -or $_.PathName -clike "*$FileName*" 
        } | Select-Object -First 1

        if ($serviceMatch -and $serviceMatch.StartMode -eq "Auto") {
            return "Yes (Windows Service: Automatic)"
        }
    }
    catch {
        # WMI error during service path lookup
    }

    # If no matches found after all checks
    return $StartupStatus
}


# ===========================================================================
# EXECUTION
# ===========================================================================

# Call the function with the user-defined path and output the result
$Result = Get-StartupStatus -ExecutablePath $ExecutablePathToCheck

# Final output in a clear format
[PSCustomObject]@{
    Executable = $ExecutablePathToCheck
    RunsAtStartup = $Result.Split(' ')[0] # Yes or No
    ConfigurationLocation = $Result.Split(' ', 2)[-1] # The source (Registry, Folder, etc.)
} | Format-Table -AutoSize