##Borrowed from Patrick /s (PatrickS#0828) on WinAdmins Discord (https://discord.gg/winadmins)

#Requires -RunAsAdministrator
#Requires -Modules "Dism"
Set-StrictMode -Version "latest"
Clear-Host

function Mount-Image
{
    param (
        [string]$WimFilePath,
        [uint32]$Index
    )

    [string]$mountPath = (Get-WindowsImage -Mounted | Where-Object { ($_.ImagePath -eq $WimFilePath) -and ($_.ImageIndex -eq $Index) } | Select-Object -ExpandProperty "MountPath")

    if ([string]::IsNullOrEmpty($mountPath))
    {
        Write-Host "`"$($WimFilePath)`" index $($Index) does not appear to be mounted."

        if (Test-Path -Path $WimFilePath)
        {
            Write-Host "Attempting to mount WIM."

            [string]$wimMountPath = Join-Path ([IO.Path]::GetPathRoot(([Environment]::SystemDirectory))) ([Guid]::NewGuid().ToString("D"))
            if (!(Test-Path -Path $wimMountPath)) { New-Item -Path $wimMountPath -ItemType "Directory" | Out-Null }

            Mount-WindowsImage -Path $wimMountPath -ImagePath $WimFilePath -Index $Index -ReadOnly | Out-Null
            Start-Sleep -Seconds 5
        }
        else
        {
            Write-Host "`"$($WimFilePath)`" does not exist."
        }

        $mountPath = (Get-WindowsImage -Mounted | Where-Object { ($_.ImagePath -eq $WimFilePath) -and ($_.ImageIndex -eq $Index) } | Select-Object -ExpandProperty "MountPath")
        
        Write-Output $mountPath
    }
    else
    {
        Write-Output $mountPath
    }
}

function Get-ScheduledTaskName
{
    param (
        [string]$WimMountPath
    )

    Write-Output "Cleanup Mounted WIM ($(Split-Path -Path $WimMountPath -Leaf))"
}

function New-ScheduledTask
{
    param (
        [string]$WimMountPath
    )   

    # Register a scheduled task to dismount the WIM, in case something goes wrong during installation.
    Write-Host "Creating a scheduled task to dismount the WIM and remove the mount folder."
    $trigger = New-ScheduledTaskTrigger -AtStartup -RandomDelay (New-TimeSpan -Minutes 5)
    $trigger.EndBoundary = (Get-Date).AddYears(69).ToString('s')
    $actions = @(
                (New-ScheduledTaskAction -Execute 'PowerShell.exe' -WorkingDirectory ([IO.Path]::GetPathRoot(([Environment]::SystemDirectory))) -Argument "-Command `"& { Get-WindowsImage -Mounted | Where-Object { `$_.Path -eq '$($WimMountPath)' } | % { Dismount-WindowsImage -Path `$_.Path -Discard; Clear-WindowsCorruptMountPoint } }`"" ),
                (New-ScheduledTaskAction -Execute 'PowerShell.exe' -WorkingDirectory ([IO.Path]::GetPathRoot(([Environment]::SystemDirectory))) -Argument "-Command `"& { if (`$null -eq (Get-WindowsImage -Mounted | Where-Object { `$_.Path -eq '$($WimMountPath)' })) { Remove-Item -Path '$($WimMountPath)' -Recurse -Force -ErrorAction SilentlyContinue; Unregister-ScheduledTask -TaskName '$(Get-ScheduledTaskName -WimMountPath $WimMountPath)' -Confirm:`$false } }`"" )
                )
    Register-ScheduledTask -TaskName (Get-ScheduledTaskName -WimMountPath $WimMountPath) -Description 'Cleaning up a mounted WIM file after software installation.' `
        -Principal (New-ScheduledTaskPrincipal -RunLevel Highest -LogonType ServiceAccount -UserId "SYSTEM") `
        -Action $actions `
        -Trigger $trigger `
        -Settings (New-ScheduledTaskSettingsSet -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries -DeleteExpiredTaskAfter (New-TimeSpan -Minutes 5)) `
        -Force
    

}

function Get-TranscriptPath
{
    [string]$transcriptPath = "$([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath) -replace "-", " ") $((Get-Date).ToString("u"))"
    [System.IO.Path]::GetInvalidFileNameChars() | ForEach-Object { $transcriptPath = $transcriptPath -replace "\$($_)", [string]::Empty }
    $transcriptPath = $transcriptPath -replace "[\s]{2}", " "

    $transcriptPath = [System.IO.Path]::Combine(([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonApplicationData)), "Logs", "$($transcriptPath).txt")

    if (Test-Path -Path $transcriptPath) { Remove-Item -Path $transcriptPath -Force -ErrorAction SilentlyContinue }
    Write-Output $transcriptPath
}

[DateTime]$scriptStartTime = (Get-Date)

Start-Transcript -Path (Get-TranscriptPath) -Append

## TODO: Set the name of the WIM to be mounted. $PSScriptRoot assumes the WIM is in the same folder as this script.
[string]$mountPath = Mount-Image -WimFilePath (Join-Path $PSScriptRoot 'Visual Studio Community 2019.wim') -Index 1

Write-Host "WIM Mount folder is `"$($mountPath).`""

if (([string]::IsNullOrEmpty($mountPath)) -or ($null -eq (Get-ChildItem -Path $mountPath -Force -ErrorAction SilentlyContinue)))
{
    Write-Host "The WIM mount path is empty, or there is nothing in the folder."
}
else
{ # The WIM seems to be mounted correctly.

    New-ScheduledTask -WimMountPath $mountPath

    Write-Host "Starting the installation process."

    ## TODO: Specify the installer command and any arguments.
    [string]$filePath = Join-Path $mountPath 'vs_community.exe'
    [string[]]$argumentList = @('--passive', '--noWeb', '--wait')
    Start-Process -FilePath $filePath -ArgumentList $argumentList -Wait

    Start-Sleep -Seconds 5

    Write-Host "Dismounting WIM at $($mountPath)."
    Dismount-WindowsImage -Path $mountPath -Discard

    Start-Sleep -Seconds 5

    if ($null -eq (Get-WindowsImage -Mounted | Where-Object { $_.Path -eq $mountPath }))
    { # The image is no longer mounted. Remove the mount directory and the cleanup scheduled task.
        Write-Host "No mounted WIM found at $($mountPath). Removing the folder."
        Remove-Item -Path $mountPath -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host "Removing the scheduled task, since the WIM was dismounted cleanly."
        Unregister-ScheduledTask -TaskName (Get-ScheduledTaskName -WimMountPath $mountPath) -Confirm:$false
    }
}

[TimeSpan]$elapsed = (Get-Date).Subtract($scriptStartTime)
Write-Host ("Elapsed time: {0:N2} minutes." -f $elapsed.TotalMinutes)

Stop-Transcript