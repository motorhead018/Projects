# Delete a device from Configuration Manager
# This script connects to the Configuration Manager AdminService and deletes the device with the ResourceID "ResourceID"

$AdminServiceUrl = "https://SMSProviderFQDN/AdminService"
$SerialNumber = Get-WmiObject win32_bios | Select-Object -ExpandProperty SerialNumber
$ResourceID = "ResourceID"

$DeleteDeviceRequest = New-Object System.Net.Http.HttpRequestMessage(HttpMethod.Delete, "$AdminServiceUrl/wmi/SMS_Device/$ResourceID")
$DeleteDeviceRequest.Headers.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Basic", [System.Text.Encoding]::ASCII.GetBytes("username:password") | ConvertTo-Base64String)

$DeleteDeviceResponse = Invoke-RestMethod -Method Delete -Uri $DeleteDeviceRequest.RequestUri
if ($DeleteDeviceResponse.StatusCode -eq 204) {
    Write-Output "Device deleted successfully."
} else {
    Write-Output "Error deleting device. Status code: $DeleteDeviceResponse.StatusCode"
}
