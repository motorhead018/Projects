#######################################################################
#Name: Remove multiple applications, app deployments, and device/user collections
#Author: William Bluhm
#Date Created:01-September-2022
#Avilable At: https://github.com/motorhead018/Projects
#Credit given to Janik Vonrotz @ https://janikvonrotz.ch/2017/09/05/manage-the-life-cycle-of-your-sccm-applications-with-powershell-part-4-remove-applications/

#######################################################################


Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
Set-Location "$((Get-PSProvider | Where-Object {$_.Name -eq "CMSite"}).Drives.Name):"

(Get-CMApplication | Where-Object { ($_.LocalizedCategoryInstanceNames -Contains "RuckZuck") } | Select-Object LocalizedDisplayName | sort-object) | ForEach-Object {
    $Name = $_.LocalizedDisplayName
    $DeviceCollectionName = "URI_ " + $Name
    $UserCollectionName = "UAI_" + $Name 
    
    Write-Host "`nStart removal of application $Name`n"

    $answer = Read-Host "Do you really want to remove the application $($Name)? (y/n)"

    if($answer -eq "y") {

        Write-Host "Remove application deployments."
        Get-CMApplicationDeployment | Where-Object{ ($_.ApplicationName -eq $Name) } | Remove-CMApplicationDeployment -Force

        Write-Host "Remove application package."
        Get-CMApplication -Name $Name | Remove-CMApplication -Force

        Write-Host "Remove device and user collections"
        Remove-CMUserCollection -Name $UserCollectionName -Force
        Remove-CMDeviceCollection -Name $DeviceCollectionName -Force
    }

    if($answer -eq "a") {

        Write-Host "Remove application deployments."
        Get-CMApplicationDeployment | Where-Object{ ($_.ApplicationName -eq $Name) } | Remove-CMApplicationDeployment -Force

        Write-Host "Remove application package."
        Get-CMApplication -Name $Name | Remove-CMApplication -Force

        Write-Host "Remove device and user collections"
        Remove-CMUserCollection -Name $UserCollectionName -Force
        Remove-CMDeviceCollection -Name $DeviceCollectionName -Force
    }
}