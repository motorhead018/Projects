<#PSScriptInfo

.VERSION 0.0.1

.GUID ee1ba506-ac68-45f8-9f37-4555f1902353

.AUTHOR William Bluhm

.COMPANYNAME @Motorhead018

.COPYRIGHT

.TAGS Win11,AppX,Removal

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

.PRIVATEDATA

#>

<# 

.DESCRIPTION 
This script removes the built-in Windows 11 AppX packages
 
 Version 0.0.1 
 -Modification of script for my purposes.

 #>
 #===========================================================================
# Remove Windows 11 AppX Packages
#===========================================================================
#
# Written partially and maintained by: William Bluhm
# Twitter: @Motorhead018
#
#===========================================================================
#
#
#################################################
## Community Contributions to Script
#################################################
# 
# Donna Ryan - Initial layout of powershell script borrowed with appreciation from her WIM Witch powershell script.
#Code borrowed and adapted from Jordan-PDQ: https://github.com/pdq/Bonus-Content/blob/master/Appx/UninstallAppxPackages.ps1

#============================================================================================================

##Get appx Packages
$Packages = Get-AppxPackage

##Create Your Whitelist
$Whitelist = @(
    '*1527c705-839a-4832-9118-54d4Bd6a0c89*',
    '*c5e2524a-ea46-4f67-841f-6a9465d9d515*',
    '*E2A4F912-2574-4A75-9BB0-0D023378592B*',
    '*F46D4000-FD22-4DB4-AC8E-4E1DDDE828FE*',
    '*Microsoft.AAD.BrokerPlugin*',
    '*Microsoft.AccountsControl*',
    '*Microsoft.Windows.Apprep.ChxApp*',
    '*Microsoft.Windows.AssignedAccessLockApp*',
    '*Microsoft.AsyncTextService*',
    '*Microsoft.BingWeather*',
    '*Microsoft.BioEnrollment*',
    '*Microsoft.Windows.CallingShellApp*',
    '*Microsoft.Windows.CapturePicker*',
    '*Windows.CBSPreview*',
    '*MicrosoftWindows.Client.CBS*',
    '*Microsoft.Windows.CloudExperienceHost*',
    '*Microsoft.Windows.ContentDeliveryManager*',
    '*Microsoft.CredDialogHost*',
    '*Microsoft.DesktopAppInstaller*',
    '*Microsoft.ECApp*',
    '*Microsoft.HEIFImageExtension*',
    '*windows.immersivecontrolpanel*',
    '*Microsoft.LockApp*',
    '*Microsoft.MicrosoftEdge*',
    '*Microsoft.MicrosoftEdge.Stable*',
    '*Microsoft.MicrosoftEdgeDevToolsClient*',
    '*Microsoft.MSPaint*',
    '*Microsoft.Windows.NarratorQuickStart*',
    '*NcsiUwpApp*',
    '*Microsoft.net*',
    '*Microsoft.Office.OneNote*',
    '*Microsoft.Windows.OOBENetworkCaptivePortal*',
    '*Microsoft.Windows.OOBENetworkConnectionFlow*',
    '*Microsoft.Windows.ParentalControls*',
    '*Microsoft.Windows.PeopleExperienceHost*',
    '*Windows.PrintDialog*',
    '*Microsoft.ScreenSketch*',
    '*Microsoft.StorePurchaseApp*',
    '*Microsoft.UI.Xaml.CBS*',
    '*MicrosoftWindows.UndockedDevKit*',
    '*Microsoft.VP9VideoExtensions*',
    '*Microsoft.WebMediaExtensions*',
    '*Microsoft.WebpImageExtension*',
    '*Microsoft.Win32WebViewHost*',
    '*Microsoft.Windows.Photos*',
    '*Microsoft.WindowsAlarms*',
    '*Microsoft.WindowsCalculator*',
    '*Microsoft.WindowsCamera*',
    '*Microsoft.WindowsSoundRecorder*',
    '*Microsoft.WindowsStore*'
)

###Get All Dependencies
ForEach($Dependency in $Whitelist){
    (Get-AppxPackage -AllUsers -Name "$Dependency").dependencies | Foreach-object{
        $NewAdd = "*" + $_.Name + "*"
        if($_.name -ne $null -and $Whitelist -notcontains $NewAdd){
            $Whitelist += $NewAdd
       }
    }
}

##View all applications not in your whitelist
ForEach($App in $Packages){
    $Matched = $false
    Foreach($Item in $Whitelist){
        If($App -like $Item){
            $Matched = $true
            break
        }
    }
    ###Nonremovable attribute does not exist before 1809, so if you are running this on an earlier build remove "-and $app.NonRemovable -eq $false" rt it will attempt to remove everything
    if($matched -eq $false -and $app.NonRemovable -eq $false){
        Get-AppxPackage -AllUsers -Name $App.Name -PackageTypeFilter Bundle  | Remove-AppxPackage -AllUsers
    }
}