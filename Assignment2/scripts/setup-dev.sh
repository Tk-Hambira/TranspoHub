#!/bin/bash

# Development Environment Setup Script for Linux/Mac
# This script sets up the development environment for the Smart Public Transport Ticketing System

echo "Setting up Smart Public Transport Ticketing System Development Environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Check if Docker is installed and running
echo -e "${YELLOW}Checking Docker installation...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker and try again.${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}Docker is installed and running${NC}"

# Check if Docker Compose is available
echo -e "${YELLOW}Checking Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}Docker Compose is available${NC}"

# Create necessary directories if they don't exist
echo -e "${YELLOW}Creating project directories...${NC}"
directories=(
    "services/passenger-service"
    "services/transport-service" 
    "services/ticketing-service"
    "services/payment-service"
    "services/notification-service"
    "services/admin-service"
    "logs"
    "data/mongodb"
    "data/kafka"
    "data/redis"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "${GREEN}Created directory: $dir${NC}"
    fi
done

# Copy template files to each service directory
echo -e "${YELLOW}Setting up service templates...${NC}"
services=("passenger-service" "transport-service" "ticketing-service" "payment-service" "notification-service" "admin-service")

for service in "${services[@]}"; do
    service_path="services/$service"
    
    # Copy Dockerfile
    cp "infrastructure/docker/Dockerfile.ballerina" "$service_path/Dockerfile"
    
    # Copy Ballerina.toml and customize
    sed "s/service_template/$service/g" "infrastructure/docker/Ballerina.toml" > "$service_path/Ballerina.toml"
    
    # Copy Config.toml
    cp "infrastructure/docker/Config.toml" "$service_path/Config.toml"
    
    echo -e "${GREEN}Set up templates for $service${NC}"
done

# Make Kafka init script executable
echo -e "${YELLOW}Making Kafka init script executable...${NC}"
chmod +x infrastructure/kafka/init-topics.sh

# Start infrastructure services
echo -e "${YELLOW}Starting infrastructure services...${NC}"
echo -e "${CYAN}This may take a few minutes on first run as Docker images are downloaded...${NC}"

# Start only infrastructure services first
docker-compose up -d zookeeper kafka mongodb redis

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 30

# Check if services are running
echo -e "${YELLOW}Checking service status...${NC}"
if docker-compose ps | grep -q "kafka.*Up" && docker-compose ps | grep -q "mongodb.*Up"; then
    echo -e "${GREEN}Infrastructure services are running!${NC}"
    
    # Initialize Kafka topics
    echo -e "${YELLOW}Initializing Kafka topics...${NC}"
    docker exec kafka bash -c "cd /app && ./infrastructure/kafka/init-topics.sh" || {
        echo -e "${YELLOW}Running Kafka topic initialization from host...${NC}"
        ./infrastructure/kafka/init-topics.sh
    }
    
    # Start management UIs
    echo -e "${YELLOW}Starting management interfaces...${NC}"
    docker-compose up -d kafka-ui mongo-express
    
    echo -e "\n${GREEN}Development environment setup complete!${NC}"
    echo -e "\n${CYAN}Access URLs:${NC}"
    echo -e "${WHITE}- Kafka UI: http://localhost:8080${NC}"
    echo -e "${WHITE}- MongoDB Express: http://localhost:8081${NC}"
    echo -e "${WHITE}- MongoDB: mongodb://admin:password123@localhost:27017${NC}"
    echo -e "${WHITE}- Kafka: localhost:9092${NC}"
    echo -e "${WHITE}- Redis: localhost:6379 (password: redis123)${NC}"
    
    echo -e "\n${CYAN}Next steps:${NC}"
    echo -e "${WHITE}1. Implement individual microservices in their respective directories${NC}"
    echo -e "${WHITE}2. Build and run services using: docker-compose up -d <service-name>${NC}"
    echo -e "${WHITE}3. View logs using: docker-compose logs -f <service-name>${NC}"
    echo -e "${WHITE}4. Stop all services using: docker-compose down${NC}"
    
else
    echo -e "${RED}Some infrastructure services failed to start. Please check Docker logs:${NC}"
    echo -e "${CYAN}docker-compose logs${NC}"
    exit 1
fi

echo -e "\n${GREEN}Development environment is ready for development!${NC}"
