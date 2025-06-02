# PowerShell script to disable desktop widgets, Task View, and hide search box for all users in Windows 11 23H2

# Ensure script runs with elevated privileges
$ErrorActionPreference = "Stop"
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script requires administrative privileges. Please run as Administrator."
    exit 1
}

# Define registry paths
$defaultUserHive = "HKU\DefaultUser"
$registryPathTaskbar = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$registryPathWidgets = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
$registryPathSearch = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"

# Load the Default User hive if not already loaded
if (-not (Test-Path $defaultUserHive)) {
    reg load HKU\DefaultUser C:\Users\Default\NTUSER.DAT | Out-Null
}

try {
    # Disable Task View
    New-ItemProperty -Path "$registryPathTaskbar" -Name "ShowTaskViewButton" -Value 0 -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path "$defaultUserHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -PropertyType DWORD -Force | Out-Null

    # Disable Widgets
    if (-not (Test-Path $registryPathWidgets)) {
        New-Item -Path $registryPathWidgets -Force | Out-Null
    }
    New-ItemProperty -Path $registryPathWidgets -Name "AllowDsh" -Value 0 -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path "$defaultUserHive\Software\Microsoft\Windows\CurrentVersion\Dsh" -Name "AllowDsh" -Value 0 -PropertyType DWORD -Force | Out-Null

    # Hide Search Box
    if (-not (Test-Path $registryPathSearch)) {
        New-Item -Path $registryPathSearch -Force | Out-Null
    }
    New-ItemProperty -Path $registryPathSearch -Name "SearchboxTaskbarMode" -Value 0 -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path "$defaultUserHive\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -PropertyType DWORD -Force | Out-Null

    Write-Output "Successfully disabled Task View, Widgets, and hid Search box for all users."
}
catch {
    Write-Error "An error occurred while modifying registry settings: $_"
}
finally {
    # Unload the Default User hive if it was loaded
    if (Test-Path $defaultUserHive) {
        [gc]::Collect()
        reg unload HKU\DefaultUser | Out-Null
    }
}