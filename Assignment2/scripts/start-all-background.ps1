#!/usr/bin/env pwsh
# Start All Services in Background Jobs
# Smart Public Transport Ticketing System

Write-Host "🚀 STARTING ALL MICROSERVICES IN BACKGROUND" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Stop any existing jobs
Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue

# Function to start service as background job
function Start-ServiceJob {
    param(
        [string]$ServiceName,
        [string]$ServicePath,
        [int]$Port
    )
    
    Write-Host "🔄 Starting $ServiceName (Port $Port)..." -ForegroundColor Yellow
    
    $job = Start-Job -Name $ServiceName -ScriptBlock {
        param($path, $serviceName, $port)
        Set-Location $path
        Write-Output "🟢 $serviceName starting on port $port..."
        & bal run
    } -ArgumentList $ServicePath, $ServiceName, $Port
    
    return $job
}

# Get project root
$projectRoot = Get-Location

# Start all services as background jobs
$jobs = @()
$jobs += Start-ServiceJob "PassengerService" "$projectRoot\services\passenger-service" 8080
$jobs += Start-ServiceJob "TransportService" "$projectRoot\services\transport-service" 8002
$jobs += Start-ServiceJob "TicketingService" "$projectRoot\services\ticketing-service" 8003
$jobs += Start-ServiceJob "PaymentService" "$projectRoot\services\payment-service" 8004
$jobs += Start-ServiceJob "NotificationService" "$projectRoot\services\notification-service" 8005
$jobs += Start-ServiceJob "AdminService" "$projectRoot\services\admin-service" 8006

Write-Host ""
Write-Host "⏳ Waiting 15 seconds for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host ""
Write-Host "🔍 CHECKING SERVICE HEALTH..." -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Health check all services
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
    try {
        $response = Invoke-RestMethod -Uri $service.Url -TimeoutSec 3
        if ($response.status -eq "UP") {
            Write-Host "✅ $($service.Name): HEALTHY" -ForegroundColor Green
            $healthyCount++
        } else {
            Write-Host "⚠️  $($service.Name): UNHEALTHY" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ $($service.Name): OFFLINE" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📊 RESULT: $healthyCount/6 services are running" -ForegroundColor $(if($healthyCount -eq 6){"Green"}else{"Yellow"})

if ($healthyCount -eq 6) {
    Write-Host ""
    Write-Host "🎉 ALL SERVICES STARTED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 API ENDPOINTS:" -ForegroundColor Cyan
    Write-Host "   • Passenger:    http://localhost:8080/api/v1/passengers/" -ForegroundColor White
    Write-Host "   • Transport:    http://localhost:8002/api/v1/transport/" -ForegroundColor White
    Write-Host "   • Ticketing:    http://localhost:8003/api/v1/tickets/" -ForegroundColor White
    Write-Host "   • Payment:      http://localhost:8004/api/v1/payments/" -ForegroundColor White
    Write-Host "   • Notification: http://localhost:8005/api/v1/notifications/" -ForegroundColor White
    Write-Host "   • Admin:        http://localhost:8006/api/v1/admin/" -ForegroundColor White
}

Write-Host ""
Write-Host "🔧 MANAGEMENT COMMANDS:" -ForegroundColor Gray
Write-Host "   • View jobs:    Get-Job" -ForegroundColor Gray
Write-Host "   • Stop all:     Get-Job | Remove-Job -Force" -ForegroundColor Gray
Write-Host "   • View output:  Receive-Job -Name ServiceName" -ForegroundColor Gray
