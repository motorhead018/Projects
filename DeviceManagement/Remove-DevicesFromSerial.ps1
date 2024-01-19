<#
    .DESCRIPTION
        Remove device object(s) from AD and CM with a name matching the serial number of the device running the script

    .NOTES
        Created by: Now Micro, Inc.
        Created date: 2023-12-19

    .CHANGELOG
        2023-12-19 - Initial Commit
        2023-12-29 - 

    .TODO
        -add error handling
        -add reporting via email
        -add handling to not delete current device name
        -add protection from deletion when too many objects are found
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

# Main Program ===================================================================================================

# Get the device serial number
$SerialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber
# Remove matching devices from Active Directory
$ADResults = Remove-DeviceAD -SerialNumber $SerialNumber -TargetOU "LDAP://OU=MyOUName,DC=MyDomainName,DC=MyDomainSuffix"
# Remove matching devices from Configuration Manager
$CMResults = Remove-DeviceCM -SerialNumber $SerialNumber -SiteServer "MySiteServerFQDN" -SiteCode "MySiteCode"
# Report results
Show-Results -ADResults $ADResults -CMResults $CMResults