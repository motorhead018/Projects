<#
    .DESCRIPTION
        Remove device object(s) from AD and CM with a name matching the serial number of the device running the script

    .NOTES
        Created by: Now Micro, Inc.
        Created date: 2023-12-19

    .CHANGELOG
        2023-12-19 - Initial Commit
        2024-01-23 - Updated with error handling and reporting via email
        2024-01-29 - Updated with search refinements: exclude device with matching serial number from results, and breaking out of the script if there are too many results.

    .TODO
        -add handling to search function that when searching for devices by serial numbers, if the current device name contains the serial number, it needs to be excluded from the search results.
        -add handling for when too many results are returned. If the search results are over 10, break out of the script.
#>

# Functions ======================================================================================================

function Remove-DeviceAD
{
    [CmdletBinding()]
    param
    (   
        [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
        [String]$SerialNumber,
        [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
        [String]$TargetOU
    )

    try {
        $ADResults = @()
        $SearchAD = [System.DirectoryServices.DirectorySearcher]$TargetOU
        $SearchAD.Filter = "(&(objectclass=computer)(name=*$SerialNumber))"
        $ADComputers = $SearchAD.FindAll()
        ForEach($ADComputer in $ADComputers)
        {
            $ADResults += ($ADComputer.GetDirectoryEntry()).DistinguishedName
            ($ADComputer.GetDirectoryEntry()).DeleteTree()
        }
        return $ADResults
    }
    catch {
        Write-Error "Error removing device from Active Directory: $_"
        return @()
    }
}

function Remove-DeviceCM
{
    [CmdletBinding()]
    param
    (   
        [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
        [String]$SerialNumber,
        [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
        [String]$SiteCode,
        [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
        [String]$SiteServer
    )

    try {
        $CMResults = @()
        $Query = $ExecutionContext.InvokeCommand.ExpandString("Select * From SMS_R_SYSTEM WHERE Name Like '%$SerialNumber'")
        $CMComputers = Get-CimInstance -Namespace "ROOT\SMS\Site_$($SiteCode)" -Query $Query -ComputerName $SiteServer
        ForEach($CMComputer in $CMComputers)
        {
            $CMResults += $CMComputer.Name
            $CMComputer | Remove-CimInstance -Confirm:$false
        }
        return $CMResults
    }
    catch {
        Write-Error "Error removing device from Configuration Manager: $_"
        return @()
    }
}

function Show-Results
{
    [CmdletBinding()]
    param
    (   
        [parameter(Mandatory=$true)]
        [String[]]$ADResults,
        [parameter(Mandatory=$true)]
        [String[]]$CMResults
    )
    if($ADResults.Count -gt 0)
    {
        Write-Output "Removed the following device object(s) from Active Directory:"
        ForEach($ADResult in $ADResults)
        {
            Write-Output $ADresult
        }
    }
    else
    {
        Write-Output "No matching Active Directory devices found"
    }
    if($CMResults.Count -gt 0)
    {
        Write-Output "Removed the following device object(s) from Configuration Manager:"
        ForEach($CMResult in $CMResults)
        {
            Write-Output $CMresult
        }
    }
    else
    {
        Write-Output "No matching Configuration Manager devices found"
    }
}

function Send-EmailReport
{
    param (
        [String]$Subject,
        [String]$Body
    )

    $EmailParams = @{
        SmtpServer  = "your-smtp-server"
        From        = "sender@example.com"
        To          = "recipient@example.com"
        Subject     = $Subject
        Body        = $Body
    }

    Send-MailMessage @EmailParams
}

# Main Program ===================================================================================================

# Get the device serial number
$SerialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber
# Remove matching devices from Active Directory
$ADResults = Remove-DeviceAD -SerialNumber $SerialNumber -TargetOU "LDAP://OU=MyOUName,DC=MyDomainName,DC=MyDomainSuffix"
# Remove matching devices from Configuration Manager
$CMResults = Remove-DeviceCM -SerialNumber $SerialNumber -SiteServer "MySiteServerFQDN" -SiteCode "MySiteCode"
# Report results
Show-Results -ADResults $ADResults -CMResults $CMResults

# Send email report
$EmailSubject = "Device Removal Script Report"
$EmailBody = "Script execution completed.`r`n"
$EmailBody += "Removed devices from Active Directory:`r`n $($ADResults -join "`r`n")`r`n"
$EmailBody += "Removed devices from Configuration Manager:`r`n $($CMResults -join "`r`n")`r`n"

Send-EmailReport -Subject $EmailSubject -Body $EmailBody
