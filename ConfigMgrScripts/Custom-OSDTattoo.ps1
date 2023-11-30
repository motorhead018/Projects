<#
.SYNOPSIS
    Script to tattoo the registry/WMI/ with deployment variables during OS deployment 

.DESCRIPTION
    This script will capture certain data points during OSD and save them to the registry, WMI, and/or environmental variables.

.PARAMETER SiteServer
    Site server name with SMS Provider installed.

.EXAMPLE
    # Get all device models on a Primary Site server called 'CM01':
    .\Get-CMDeviceModels.ps1 -SiteServer CM01
    
.NOTES
    FileName:    Custom-OSDTattoo.ps1
    Author:      William Bluhm
    Contact:     @Motorhead018
    Created:     2023-11-29
    Updated:     

    Version history:
    1.0.0 - (2023-11-29) Script created

.REFERENCES
    -Jörgen Nilsson's OSDTattoo.ps1 - https://github.com/Ccmexec/MEMCM-OSD-Scripts/blob/master/OSDTattoo.ps1
    -The Deployment Bunny's CustomZTITattoo - https://deploymentbunny.com/2016/12/02/osd-add-information-to-the-computer-during-osd-using-a-custom-tattoo-step/
    -Stephane van Gulick's OSD Tattooer Script - http://www.powershelldistrict.com/osd-tattoo-powershell/

#>

$RegKeyName = "JBL_OSD"

# Set values
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$FullRegKeyName = "HKLM:\SOFTWARE\" + $regkeyname 

# Create Registry key
New-Item -Path $FullRegKeyName -type Directory -Force -ErrorAction SilentlyContinue

# Get values
$InstallTime = Get-Date -Format G 
$OSDStartTime = $tsenv.Value("OSDStartTime")
$AdvertisementID = $tsenv.Value("_SMSTSAdvertID")
$Organization = $tsenv.value("OSDBranding")
$TaskSequenceID = $tsenv.value("_SMSTSPackageID")
$Packagename = $tsenv.value("_SMSTSPackageName")
$MachineName = $env:computername
$Installationmode = $tsenv.value("_SMSTSLaunchMode")

#Calculate time elapsed
$OSDTImeSpan = New-TimeSpan -start $OSDstartTime -end $installtime
$OSDDuration = "{0:hh}:{0:mm}:{0:ss}" -f $OSDTimeSpan

# Write values
new-itemproperty $FullRegKeyName -Name "Installed Date" -Value $InstallTime -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
new-itemproperty $FullRegKeyName -Name "OSD Start Time" -Value $OSDStartTime -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty $FullRegKeyName -Name "OSD Duration" -Value $OSDDuration -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
new-itemproperty $FullRegKeyName -Name "OrganizationName" -Value $Organization -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
new-itemproperty $FullRegKeyName -Name "AdvertisementID" -Value $AdvertisementID -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
new-itemproperty $FullRegKeyName -Name "TaskSequenceID" -Value $TaskSequenceID -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
new-itemproperty $FullRegKeyName -Name "Task Sequence Name" -Value $Packagename -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
new-itemproperty $FullRegKeyName -Name "Installation Type" -Value $Installationmode -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
new-itemproperty $FullRegKeyName -Name "Computername" -Value $MachineName -Type STRING -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty $FullRegKeyName -Name "OS Version" -value (Get-CimInstance Win32_Operatingsystem).version -PropertyType String -Force | Out-Null