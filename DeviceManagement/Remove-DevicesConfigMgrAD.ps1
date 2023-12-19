#######################################################################
#Name: Remove multiple applications, app deployments, and device/user collections
#Author: William Bluhm
#Date Created:19-December-2023
#Avilable At: https://github.com/motorhead018/Projects

#References:
 

#######################################################################

Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
Set-Location "$((Get-PSProvider | Where-Object {$_.Name -eq "CMSite"}).Drives.Name):"