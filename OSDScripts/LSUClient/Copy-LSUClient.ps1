# Get the latest version of LSUClient from the source directory
$sourcePath = ".\LSUClient"
$destinationBasePath = "C:\Program Files\WindowsPowerShell\Modules\LSUClient"

# Find the highest version folder
$latestVersion = Get-ChildItem -Path $sourcePath -Directory |
    Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } |
    Sort-Object { [Version]$_.Name } -Descending |
    Select-Object -First 1

if (-not $latestVersion) {
    Write-Error "No valid version folder found in $sourcePath"
    exit 1
}

# Create destination path with version number
$destinationPath = Join-Path $destinationBasePath $latestVersion.Name

# Copy the latest version to the destination
try {
    Copy-Item -Path $latestVersion.FullName -Destination $destinationPath -Recurse -Force -ErrorAction Stop
    Write-Host "Successfully copied LSUClient version $($latestVersion.Name) to $destinationPath"
}
catch {
    Write-Error "Failed to copy LSUClient version $($latestVersion.Name): $_"
    exit 1
}

# Verify the copy operation
$sourceFiles = Get-ChildItem -Path $latestVersion.FullName -Recurse -File
$destFiles = Get-ChildItem -Path $destinationPath -Recurse -File

if ($sourceFiles.Count -eq $destFiles.Count) {
    Write-Host "Copy verification successful: $($sourceFiles.Count) files copied"
}
else {
    Write-Error "Copy verification failed: Source has $($sourceFiles.Count) files, but destination has $($destFiles.Count) files"
    exit 1
}

# Delete older version folders in the destination
Get-ChildItem -Path $destinationBasePath -Directory |
    Where-Object { 
        $_.Name -match '^\d+\.\d+\.\d+$' -and 
        [Version]$_.Name -lt [Version]$latestVersion.Name 
    } | ForEach-Object {
        try {
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop
            Write-Host "Removed older version: $($_.Name)"
        }
        catch {
            Write-Warning "Failed to remove older version $($_.Name): $_"
        }
    }

# Import the module
try {
    Import-Module -Name (Join-Path $destinationPath "LSUClient.psd1") -Force -ErrorAction Stop
    Write-Host "Successfully imported LSUClient module version $($latestVersion.Name)"
}
catch {
    Write-Error "Failed to import LSUClient module: $_"
    exit 1
}