# Script to unpin Microsoft Store and Microsoft Copilot from the taskbar for all users

# Function to unpin an app from the taskbar
function Remove-AppFromTaskbar {
    param (
        [string]$AppName
    )
    
    try {
        # Get the taskbar layout from the default user registry
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
        $taskband = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
        
        if ($taskband) {
            # Load the taskbar pinned items
            $pinnedItems = [System.Text.Encoding]::Unicode.GetString($taskband.Favorites)
            
            # Check if the app is pinned
            if ($pinnedItems -like "*$AppName*") {
                # Remove the app from pinned items
                $newPinnedItems = $pinnedItems -replace [regex]::Escape($AppName), ""
                
                # Update the registry
                Set-ItemProperty -Path $regPath -Name "Favorites" -Value $newPinnedItems
                Write-Host "Successfully unpinned $AppName from taskbar"
            }
        }
    }
    catch {
        Write-Host "Error unpinning $AppName : $_"
    }
}

# Define the apps to unpin
$appsToUnpin = @(
    "Microsoft Store",
    "Microsoft Copilot"
)

# Unpin each app
foreach ($app in $appsToUnpin) {
    Unpin-AppFromTaskbar -AppName $app
}

# Apply changes to default user profile for new users
$defaultProfile = "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\"
$layoutFile = Join-Path $defaultProfile "LayoutModification.xml"

if (Test-Path $layoutFile) {
    try {
        # Read the current layout
        $xml = [xml](Get-Content $layoutFile)
        
        # Remove Microsoft Store and Copilot from taskbar
        $nodesToRemove = $xml.SelectNodes("//taskbar:TaskbarPinList/taskbar:DesktopApp[@DesktopApplicationName='Microsoft Store' or @DesktopApplicationName='Microsoft Copilot']")
        
        foreach ($node in $nodesToRemove) {
            $node.ParentNode.RemoveChild($node) | Out-Null
        }
        
        # Save the modified layout
        $xml.Save($layoutFile)
        Write-Host "Updated default user profile taskbar layout"
    }
    catch {
        Write-Host "Error updating default profile: $_"
    }
}

# Force refresh of taskbar
Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
Start-Process "explorer"

Write-Host "Taskbar unpinning complete"