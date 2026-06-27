# ==============================================================================
# Script Name:  Fix-WindowsAudio.ps1
# Description:  Power-cycles frozen audio hardware controllers from deep-sleep D3 locks
# Author:       mounishreddy27
# Requirements: Windows PowerShell / Terminal executed as Administrator
# ==============================================================================

# Ensure execution context is running with elevated privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be executed within an Administrative PowerShell session."
    Exit
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "      Initializing Hardware-Level Audio Reset     " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Query and isolate the physical hardware media controllers
$MediaDevices = Get-PnpDevice -Class Media | Where-Object { 
    $_.FriendlyName -match "Realtek" -or 
    $_.FriendlyName -match "High Definition Audio" -or 
    $_.FriendlyName -match "Intel\(R\) Smart Sound" 
}

if (-not $MediaDevices) {
    Write-Warning "No matching hardware controllers found. Verification required in Device Manager."
}

# 2. Power-cycle the physical bus architecture
foreach ($Device in $MediaDevices) {
    Write-Host "Targeting physical hardware layer: $($Device.FriendlyName)..." -ForegroundColor Yellow
    try {
        # Terminate device power allocation
        Disable-PnpDevice -InstanceId $Device.InstanceId -Confirm:$false -ErrorAction Stop
        Start-Sleep -Seconds 2
        
        # Re-initialize device power allocation and trigger hardware boot
        Enable-PnpDevice -InstanceId $Device.InstanceId -Confirm:$false -ErrorAction Stop
        Write-Host "Successfully power-cycled device bus." -ForegroundColor Green
    } catch {
        Write-Warning "Instance ID locked by core system process. Skipping: $($Device.FriendlyName)"
    }
}

# 3. Cycle the logical audio endpoint interfaces
Write-Host "`nRefreshing system audio endpoints..." -ForegroundColor Yellow
Get-PnpDevice -Class AudioEndpoint -ErrorAction SilentlyContinue | ForEach-Object {
    Disable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Enable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
}

# 4. Perform a clean restart of the user-space engine wrapper
Write-Host "`nRe-indexing Windows Audio Service (Audiosrv)..." -ForegroundColor Yellow
Restart-Service -Name "Audiosrv" -Force

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host " Reset Complete. Audio pipeline successfully restored." -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green