<#
    .DESCRIPTION
        Remove device object(s) from AD and CM with a name matching the serial number of the device running the script. The intention is to have the script run towards the end of the task sequence ie when it is in Windows.

    .NOTES
        Created by: Now Micro, Inc.
        Created date: 2023-12-19

    .CHANGELOG
        2023-12-19: Initial Commit
        2024-01-23: Updated with error handling and reporting via email
        2024-02-02: Updated with search refinements: exclude device with matching serial number from results. Still need to add: breaking out of the script if there are too many results.
        2024-02-05: Added the Write-Log function created by  Nickolaj Andersen and Maurice Daly. Modified by Jon Anderson. 

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

        ForEach($ADComputer in $ADComputers) {
        
          #Check to see if the current computer name is found in $ADComputerName
          if ($ADComputer -eq "$env:computername") {
              Write-Output "Skipping current computer ($ADComputerName) from removal."
              continue
          }  
          
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

# Function to Send Notifications to Microsoft Teams via Webhook
function Send-TeamsNotification {
    param (
        [string]$WebhookUrl,
        [string]$Message
    )

    $Body = @{
        text = $Message
    } | ConvertTo-Json

    $Result = Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $Body -ContentType "application/json"

    if ($Result -eq "1") {
        Write-Host "Notification sent to Microsoft Teams successfully."
    } else {
        Write-Warning "Failed to send notification to Microsoft Teams."
    }
}

function Write-LogEntry
{
    <#
        .DESCRIPTION
            Write data to a CMTrace compatible log file

        .PARAMETER Value
            The data to write to the log file

        .PARAMETER Severity
            The severity of the log file entry (1 = Information, 2 = Warning, 3 = Error)

        .PARAMETER FileName
            The name of the log file

        .EXAMPLE
            Write-LogEntry -Value "This is a log entry" -Severity 1

        .NOTES
            Created by: Nickolaj Andersen / Maurice Daly
            Modified by: Jon Anderson
            Modified: 2023-09-06

    #>
	param(
		[parameter(Mandatory = $true, HelpMessage = "Value added to the log file.")][ValidateNotNullOrEmpty()]
        [string]$Value,
		[parameter(Mandatory = $true, HelpMessage = "Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")][ValidateNotNullOrEmpty()][ValidateSet("1", "2", "3")]
        [string]$Severity,
		[parameter(Mandatory = $false, HelpMessage = "Name of the log file that the entry will written to.")][ValidateNotNullOrEmpty()]
        [string]$FileName = "Win32AppManagement.log"
	)

	$LogFilePath = Join-Path -Path $LogsDirectory -ChildPath $FileName
	if(-not(Test-Path -Path 'variable:global:TimezoneBias'))
	{
		[string]$global:TimezoneBias = [System.TimeZoneInfo]::Local.GetUtcOffset((Get-Date)).TotalMinutes
		if($TimezoneBias -match "^-")
		{
			$TimezoneBias = $TimezoneBias.Replace('-', '+')
		}
		else
		{
			$TimezoneBias = '-' + $TimezoneBias
		}
	}
	$Time = -join @((Get-Date -Format "HH:mm:ss.fff"), $TimezoneBias)	
	$Date = (Get-Date -Format "MM-dd-yyyy")
	$Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
	$LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""Win32AppManagement"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
	try
	{
		Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop
	}
	catch [System.Exception]
	{
		Write-Warning -Message "Unable to append log entry to $FileName file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
	}
}

# Main Program ===================================================================================================

# Define Log File Path
$LogFilePath = "C:\Windows\CCM\Logs\DeviceRemovalScript.log"

# Log script start
Write-LogEntry -Value "Script started" -Severity 1 -FileName $LogFilePath

try {
    # Get the device serial number
    $SerialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber

    # Log serial number
    Write-LogEntry -Value "Serial number: $SerialNumber" -Severity 1 -FileName $LogFilePath

    # Remove matching devices from Active Directory
    $ADResults = Remove-DeviceAD -SerialNumber $SerialNumber -TargetOU "LDAP://OU=MyOUName,DC=MyDomainName,DC=MyDomainSuffix"

    # Log Active Directory removal results
    Write-LogEntry -Value "Removed devices from Active Directory:`r`n$($ADResults -join "`r`n")" -Severity 1 -FileName $LogFilePath

    # Remove matching devices from Configuration Manager
    $CMResults = Remove-DeviceCM -SerialNumber $SerialNumber -SiteServer "MySiteServerFQDN" -SiteCode "MySiteCode"

    # Log Configuration Manager removal results
    Write-LogEntry -Value "Removed devices from Configuration Manager:`r`n$($CMResults -join "`r`n")" -Severity 1 -FileName $LogFilePath

    # Report results
    Show-Results -ADResults $ADResults -CMResults $CMResults

    # Send notification to Microsoft Teams
    $TeamsMessage = "Script execution completed.`r`n"
    $TeamsMessage += "Removed devices from Active Directory:`r`n$($ADResults -join "`r`n")`r`n"
    $TeamsMessage += "Removed devices from Configuration Manager:`r`n$($CMResults -join "`r`n")`r`n"

    Write-LogEntry -Value $EmailBody -Severity 1 -FileName $LogFilePath

    Send-TeamsNotification -WebhookUrl $TeamsWebhookUrl -Message $TeamsMessage

    # Log script end
    Write-LogEntry -Value "Script completed" -Severity 1 -FileName $LogFilePath
}
catch {
    # Log error
    Write-LogEntry -Value "Error: $_" -Severity 3 -FileName $LogFilePath
    # Handle error as needed
    
}
