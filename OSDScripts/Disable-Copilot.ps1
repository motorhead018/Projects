# Disable Microsoft Copilot for all users
# Run with elevated privileges during task sequence

# Define registry paths
$regPath1 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
$regPath2 = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

# Create or update registry keys to disable Copilot
try {
    # Disable Copilot in Windows
    if (-not (Test-Path $regPath1)) {
        New-Item -Path $regPath1 -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath1 -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force

    # Disable Copilot in Microsoft Edge
    if (-not (Test-Path $regPath2)) {
        New-Item -Path $regPath2 -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath2 -Name "HubsSidebarEnabled" -Value 0 -Type DWord -Force

    Write-Output "Microsoft Copilot has been disabled for all users."
}
catch {
    Write-Error "Failed to disable Copilot: $_"
    exit 1
}

# Exit successfully
exit 0