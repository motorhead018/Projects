# Script to align the Start menu to the left on the taskbar for all users in Windows 11 23H2
# Intended for use during a task sequence (e.g., ConfigMgr or MDT)

# Define registry path and value for taskbar alignment
$registryPath = "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$registryValueName = "TaskbarAl"
$registryValueData = 0  # 0 = Left alignment, 1 = Center alignment

try {
    # Load the default user registry hive
    Write-Host "Loading default user registry hive..."
    $defaultUserHive = "C:\Users\Default\NTUSER.DAT"
    reg load HKLM\Default $defaultUserHive

    # Set the registry value for taskbar alignment in the default user profile
    Write-Host "Setting TaskbarAl to 0 for default user profile..."
    New-ItemProperty -Path $registryPath -Name $registryValueName -Value $registryValueData -PropertyType DWord -Force -ErrorAction Stop

    # Unload the default user registry hive
    Write-Host "Unloading default user registry hive..."
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    reg unload HKLM\Default

    # Optionally, apply the setting to existing user profiles
    $userProfiles = Get-ChildItem -Path "C:\Users" -Directory -Exclude "Public", "Default", "Administrator"
    foreach ($profile in $userProfiles) {
        $ntuserDat = Join-Path -Path $profile.FullName -ChildPath "NTUSER.DAT"
        if (Test-Path $ntuserDat) {
            Write-Host "Processing user profile: $($profile.Name)"
            $tempHive = "HKLM\TempUser"
            reg load $tempHive $ntuserDat
            New-ItemProperty -Path "$tempHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name $registryValueName -Value $registryValueData -PropertyType DWord -Force -ErrorAction Continue
            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()
            reg unload $tempHive
        }
    }

    Write-Host "Taskbar alignment set to left for default and existing user profiles."
}
catch {
    Write-Host "Error occurred: $_"
    exit 1
}
finally {
    # Ensure the default hive is unloaded even if an error occurs
    try {
        reg unload HKLM\Default -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "Note: Default hive was already unloaded or not loaded."
    }
    try {
        reg unload HKLM\TempUser -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "Note: TempUser hive was already unloaded or not loaded."
    }
}