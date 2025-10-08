function Block-ProcessNetworkAccess {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ExecutablePath,

        [Parameter(Mandatory=$true)]
        [string]$RuleName
    )
    
    # 1. Block OUTBOUND connections for the executable
    Write-Host "Creating OUTBOUND block rule: '$($RuleName) - Outbound'..."
    New-NetFirewallRule -DisplayName "$($RuleName) - Outbound" `
        -Name "$($RuleName)-Out" `
        -Direction Outbound `
        -Program "$ExecutablePath" `
        -Action Block `
        -Profile Any `
        -Enabled True

    # 2. Block INBOUND connections for the executable
    Write-Host "Creating INBOUND block rule: '$($RuleName) - Inbound'..."
    New-NetFirewallRule -DisplayName "$($RuleName) - Inbound" `
        -Name "$($RuleName)-In" `
        -Direction Inbound `
        -Program "$ExecutablePath" `
        -Action Block `
        -Profile Any `
        -Enabled True
        
    Write-Host "`n✅ Quarantine Successful: '$RuleName' rules created for '$ExecutablePath'." -ForegroundColor Green
    Write-Host "The process must be restarted (or killed) for these rules to fully take effect." -ForegroundColor Yellow
}

# =========================================================================
# EXAMPLE USAGE: MODIFY THIS SECTION
# You would use the ExecutablePath found in your previous analysis scripts.
# =========================================================================

# Define the path of the process to quarantine
$TargetProcessPath = "C:\Users\mike.mwiti\Downloads\Windows_running_processes.ps1"

# Define a unique name for the rules
$QuarantineRuleName = "QUARANTINE_BLOCK_SUSPICIOUS_APP"

# Execute the function
Block-ProcessNetworkAccess -ExecutablePath $TargetProcessPath -RuleName $QuarantineRuleName

# -------------------------------------------------------------------------
# TO REMOVE THE RULES LATER:
# Get-NetFirewallRule -DisplayName "QUARANTINE_BLOCK_SUSPICIOUS_APP - *" | Remove-NetFirewallRule
# -------------------------------------------------------------------------