# Development Environment Setup Script for Windows PowerShell
# This script sets up the development environment for the Smart Public Transport Ticketing System

Write-Host "Setting up Smart Public Transport Ticketing System Development Environment..." -ForegroundColor Green

# Check if Docker is installed and running
Write-Host "Checking Docker installation..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "Docker is not installed or not running. Please install Docker Desktop and try again." -ForegroundColor Red
    exit 1
}

# Check if Docker Compose is available
Write-Host "Checking Docker Compose..." -ForegroundColor Yellow
try {
    $composeVersion = docker-compose --version
    Write-Host "Docker Compose found: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "Docker Compose is not available. Please ensure Docker Desktop is properly installed." -ForegroundColor Red
    exit 1
}

# Create necessary directories if they don't exist
Write-Host "Creating project directories..." -ForegroundColor Yellow
$directories = @(
    "services/passenger-service",
    "services/transport-service", 
    "services/ticketing-service",
    "services/payment-service",
    "services/notification-service",
    "services/admin-service",
    "logs",
    "data/mongodb",
    "data/kafka",
    "data/redis"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created directory: $dir" -ForegroundColor Green
    }
}

# Copy template files to each service directory
Write-Host "Setting up service templates..." -ForegroundColor Yellow
$services = @("passenger-service", "transport-service", "ticketing-service", "payment-service", "notification-service", "admin-service")

foreach ($service in $services) {
    $servicePath = "services/$service"
    
    # Copy Dockerfile
    Copy-Item "infrastructure/docker/Dockerfile.ballerina" "$servicePath/Dockerfile" -Force
    
    # Copy Ballerina.toml and customize
    $ballerinaToml = Get-Content "infrastructure/docker/Ballerina.toml" -Raw
    $ballerinaToml = $ballerinaToml -replace "service_template", $service
    $ballerinaToml | Out-File "$servicePath/Ballerina.toml" -Encoding UTF8
    
    # Copy Config.toml
    Copy-Item "infrastructure/docker/Config.toml" "$servicePath/Config.toml" -Force
    
    Write-Host "Set up templates for $service" -ForegroundColor Green
}

# Make Kafka init script executable (if on WSL/Linux subsystem)
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    Write-Host "Making Kafka init script executable..." -ForegroundColor Yellow
    wsl chmod +x infrastructure/kafka/init-topics.sh
}

# Start infrastructure services
Write-Host "Starting infrastructure services..." -ForegroundColor Yellow
Write-Host "This may take a few minutes on first run as Docker images are downloaded..." -ForegroundColor Cyan

# Start only infrastructure services first
docker-compose up -d zookeeper kafka mongodb redis

# Wait for services to be ready
Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check if services are running
Write-Host "Checking service status..." -ForegroundColor Yellow
$runningServices = docker-compose ps --services --filter "status=running"

if ($runningServices -contains "kafka" -and $runningServices -contains "mongodb") {
    Write-Host "Infrastructure services are running!" -ForegroundColor Green
    
    # Initialize Kafka topics
    Write-Host "Initializing Kafka topics..." -ForegroundColor Yellow
    if (Get-Command wsl -ErrorAction SilentlyContinue) {
        wsl bash infrastructure/kafka/init-topics.sh
    } else {
        Write-Host "WSL not available. Please run the Kafka topic initialization manually:" -ForegroundColor Yellow
        Write-Host "docker exec -it kafka bash /app/infrastructure/kafka/init-topics.sh" -ForegroundColor Cyan
    }
    
    # Start management UIs
    Write-Host "Starting management interfaces..." -ForegroundColor Yellow
    docker-compose up -d kafka-ui mongo-express
    
    Write-Host "`nDevelopment environment setup complete!" -ForegroundColor Green
    Write-Host "`nAccess URLs:" -ForegroundColor Cyan
    Write-Host "- Kafka UI: http://localhost:8080" -ForegroundColor White
    Write-Host "- MongoDB Express: http://localhost:8081" -ForegroundColor White
    Write-Host "- MongoDB: mongodb://admin:password123@localhost:27017" -ForegroundColor White
    Write-Host "- Kafka: localhost:9092" -ForegroundColor White
    Write-Host "- Redis: localhost:6379 (password: redis123)" -ForegroundColor White
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Implement individual microservices in their respective directories" -ForegroundColor White
    Write-Host "2. Build and run services using: docker-compose up -d <service-name>" -ForegroundColor White
    Write-Host "3. View logs using: docker-compose logs -f <service-name>" -ForegroundColor White
    Write-Host "4. Stop all services using: docker-compose down" -ForegroundColor White
    
} else {
    Write-Host "Some infrastructure services failed to start. Please check Docker logs:" -ForegroundColor Red
    Write-Host "docker-compose logs" -ForegroundColor Cyan
    exit 1
}

Write-Host "`nDevelopment environment is ready for development!" -ForegroundColor Green
