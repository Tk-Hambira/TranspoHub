#!/usr/bin/env pwsh
# Start All Microservices Script
# Smart Public Transport Ticketing System

Write-Host "🚀 STARTING ALL MICROSERVICES" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Function to start a service in background
function Start-Service {
    param(
        [string]$ServiceName,
        [string]$ServicePath,
        [int]$Port
    )
    
    Write-Host "🔄 Starting $ServiceName on port $Port..." -ForegroundColor Yellow
    
    # Start the service in a new PowerShell window
    $processArgs = @{
        FilePath = "powershell.exe"
        ArgumentList = @(
            "-NoExit",
            "-Command", 
            "cd '$ServicePath'; Write-Host '🟢 $ServiceName STARTING...' -ForegroundColor Green; bal run"
        )
        WindowStyle = "Normal"
    }
    
    Start-Process @processArgs
    Start-Sleep -Seconds 1
}

# Get the project root directory
$projectRoot = Split-Path -Parent $PSScriptRoot

Write-Host "📁 Project Root: $projectRoot" -ForegroundColor Gray
Write-Host ""

# Start all services
Start-Service "Passenger Service" "$projectRoot\services\passenger-service" 8080
Start-Service "Transport Service" "$projectRoot\services\transport-service" 8002
Start-Service "Ticketing Service" "$projectRoot\services\ticketing-service" 8003
Start-Service "Payment Service" "$projectRoot\services\payment-service" 8004
Start-Service "Notification Service" "$projectRoot\services\notification-service" 8005
Start-Service "Admin Service" "$projectRoot\services\admin-service" 8006

Write-Host ""
Write-Host "⏳ Waiting 10 seconds for services to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "🔍 CHECKING SERVICE HEALTH..." -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Health check function
function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$HealthUrl
    )
    
    try {
        $response = Invoke-RestMethod -Uri $HealthUrl -TimeoutSec 5
        if ($response.status -eq "UP") {
            Write-Host "✅ $ServiceName : HEALTHY" -ForegroundColor Green
            return $true
        } else {
            Write-Host "⚠️  $ServiceName : UNHEALTHY" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "❌ $ServiceName : OFFLINE" -ForegroundColor Red
        return $false
    }
}

# Test all services
$services = @(
    @{Name="Passenger Service"; Url="http://localhost:8080/api/v1/passengers/health"},
    @{Name="Transport Service"; Url="http://localhost:8002/api/v1/transport/health"},
    @{Name="Ticketing Service"; Url="http://localhost:8003/api/v1/tickets/health"},
    @{Name="Payment Service"; Url="http://localhost:8004/api/v1/payments/health"},
    @{Name="Notification Service"; Url="http://localhost:8005/api/v1/notifications/health"},
    @{Name="Admin Service"; Url="http://localhost:8006/api/v1/admin/health"}
)

$healthyCount = 0
foreach ($service in $services) {
    if (Test-ServiceHealth $service.Name $service.Url) {
        $healthyCount++
    }
}

Write-Host ""
Write-Host "📊 SUMMARY: $healthyCount/6 services are healthy" -ForegroundColor $(if($healthyCount -eq 6){"Green"}else{"Yellow"})

if ($healthyCount -eq 6) {
    Write-Host ""
    Write-Host "🎉 ALL SERVICES STARTED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "🌐 You can now test the APIs:" -ForegroundColor Cyan
    Write-Host "   • Passenger Service: http://localhost:8080" -ForegroundColor White
    Write-Host "   • Transport Service: http://localhost:8002" -ForegroundColor White
    Write-Host "   • Ticketing Service: http://localhost:8003" -ForegroundColor White
    Write-Host "   • Payment Service:   http://localhost:8004" -ForegroundColor White
    Write-Host "   • Notification Service: http://localhost:8005" -ForegroundColor White
    Write-Host "   • Admin Service:     http://localhost:8006" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "⚠️  Some services may still be starting. Wait a moment and try again." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔧 To stop all services, close the PowerShell windows or run:" -ForegroundColor Gray
Write-Host "   Get-Process powershell | Where-Object {`$_.MainWindowTitle -like '*Service*'} | Stop-Process" -ForegroundColor Gray
