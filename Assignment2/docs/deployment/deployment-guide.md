# Deployment Guide

## Overview

This guide provides instructions for deploying the Smart Public Transport Ticketing System in different environments.

## Prerequisites

### Development Environment
- Docker Desktop 4.0+
- Docker Compose 2.0+
- Ballerina 2201.8.5+
- Git
- 8GB RAM minimum
- 20GB free disk space

### Production Environment
- Kubernetes cluster 1.24+
- Helm 3.0+
- Container registry access
- Load balancer
- SSL certificates
- Monitoring tools (Prometheus, Grafana)

## Local Development Setup

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Distributed-Systems-and-Applications-Project2
   ```

2. **Run setup script**
   
   **Windows (PowerShell):**
   ```powershell
   .\scripts\setup-dev.ps1
   ```
   
   **Linux/Mac:**
   ```bash
   chmod +x scripts/setup-dev.sh
   ./scripts/setup-dev.sh
   ```

3. **Verify infrastructure services**
   ```bash
   docker-compose ps
   ```

### Manual Setup

If you prefer manual setup:

1. **Start infrastructure services**
   ```bash
   docker-compose up -d zookeeper kafka mongodb redis
   ```

2. **Wait for services to be ready**
   ```bash
   # Wait about 30 seconds for Kafka to be ready
   sleep 30
   ```

3. **Initialize Kafka topics**
   ```bash
   ./infrastructure/kafka/init-topics.sh
   ```

4. **Start management UIs**
   ```bash
   docker-compose up -d kafka-ui mongo-express
   ```

### Access Management Interfaces

- **Kafka UI**: http://localhost:8080
- **MongoDB Express**: http://localhost:8081
- **MongoDB**: mongodb://admin:password123@localhost:27017
- **Redis**: localhost:6379 (password: redis123)

## Service Development

### Building Individual Services

Each service can be developed and tested independently:

1. **Navigate to service directory**
   ```bash
   cd services/passenger-service
   ```

2. **Build the service**
   ```bash
   bal build
   ```

3. **Run locally for development**
   ```bash
   bal run
   ```

4. **Build Docker image**
   ```bash
   docker build -t passenger-service:latest .
   ```

### Running Services with Docker Compose

1. **Start specific service**
   ```bash
   docker-compose up -d passenger-service
   ```

2. **View service logs**
   ```bash
   docker-compose logs -f passenger-service
   ```

3. **Scale service**
   ```bash
   docker-compose up -d --scale passenger-service=3
   ```

## Testing

### Health Checks

All services expose health check endpoints:

```bash
# Check service health
curl http://localhost:8001/health  # Passenger Service
curl http://localhost:8002/health  # Transport Service
curl http://localhost:8003/health  # Ticketing Service
curl http://localhost:8004/health  # Payment Service
curl http://localhost:8005/health  # Notification Service
curl http://localhost:8006/health  # Admin Service
```

### Integration Testing

1. **Start all services**
   ```bash
   docker-compose up -d
   ```

2. **Run integration tests**
   ```bash
   cd tests
   # Run your test suite here
   ```

## Production Deployment

### Docker Compose Production

1. **Create production docker-compose file**
   ```yaml
   # docker-compose.prod.yml
   version: '3.8'
   services:
     # Override development settings
     passenger-service:
       environment:
         - NODE_ENV=production
         - LOG_LEVEL=warn
       deploy:
         replicas: 3
         resources:
           limits:
             memory: 512M
           reservations:
             memory: 256M
   ```

2. **Deploy to production**
   ```bash
   docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
   ```

### Kubernetes Deployment

1. **Create namespace**
   ```bash
   kubectl create namespace transport-system
   ```

2. **Deploy infrastructure**
   ```bash
   # Deploy MongoDB
   kubectl apply -f k8s/mongodb/
   
   # Deploy Kafka
   kubectl apply -f k8s/kafka/
   
   # Deploy Redis
   kubectl apply -f k8s/redis/
   ```

3. **Deploy services**
   ```bash
   kubectl apply -f k8s/services/
   ```

4. **Expose services**
   ```bash
   kubectl apply -f k8s/ingress/
   ```

## Environment Configuration

### Environment Variables

Each service requires the following environment variables:

```bash
# Database
MONGODB_URL=mongodb://admin:password123@mongodb:27017/service_db?authSource=admin

# Kafka
KAFKA_BOOTSTRAP_SERVERS=kafka:29092

# Redis
REDIS_URL=redis://redis123@redis:6379

# Security
JWT_SECRET=your_jwt_secret_key

# Service
SERVICE_PORT=8080
```

### Configuration Files

Each service uses a `Config.toml` file for configuration:

```toml
[database]
url = "${MONGODB_URL}"
name = "service_db"

[kafka]
bootstrapServers = "${KAFKA_BOOTSTRAP_SERVERS}"
groupId = "service-group"

[service]
host = "0.0.0.0"
port = "${SERVICE_PORT}"
```

## Monitoring and Logging

### Centralized Logging

1. **Add logging configuration to docker-compose**
   ```yaml
   logging:
     driver: "json-file"
     options:
       max-size: "10m"
       max-file: "3"
   ```

2. **Use ELK stack for log aggregation**
   ```bash
   docker-compose -f docker-compose.yml -f docker-compose.logging.yml up -d
   ```

### Monitoring

1. **Add Prometheus metrics**
   ```yaml
   prometheus:
     image: prom/prometheus
     ports:
       - "9090:9090"
   
   grafana:
     image: grafana/grafana
     ports:
       - "3000:3000"
   ```

2. **Configure service discovery**
   ```yaml
   # prometheus.yml
   scrape_configs:
     - job_name: 'transport-services'
       static_configs:
         - targets: ['passenger-service:8080', 'transport-service:8080']
   ```

## Backup and Recovery

### Database Backup

1. **MongoDB backup**
   ```bash
   docker exec mongodb mongodump --out /backup/$(date +%Y%m%d_%H%M%S)
   ```

2. **Automated backup script**
   ```bash
   #!/bin/bash
   # backup.sh
   DATE=$(date +%Y%m%d_%H%M%S)
   docker exec mongodb mongodump --out /backup/$DATE
   # Upload to cloud storage
   ```

### Disaster Recovery

1. **Database restore**
   ```bash
   docker exec mongodb mongorestore /backup/20251004_120000
   ```

2. **Service recovery**
   ```bash
   # Restart failed services
   docker-compose restart passenger-service
   ```

## Security

### SSL/TLS Configuration

1. **Generate certificates**
   ```bash
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
     -keyout tls.key -out tls.crt
   ```

2. **Configure HTTPS**
   ```yaml
   # nginx.conf
   server {
     listen 443 ssl;
     ssl_certificate /etc/ssl/certs/tls.crt;
     ssl_certificate_key /etc/ssl/private/tls.key;
   }
   ```

### Network Security

1. **Use Docker networks**
   ```yaml
   networks:
     transport-network:
       driver: bridge
       internal: true
   ```

2. **Configure firewall rules**
   ```bash
   # Allow only necessary ports
   ufw allow 80/tcp
   ufw allow 443/tcp
   ufw deny 27017/tcp  # Block direct MongoDB access
   ```

## Troubleshooting

### Common Issues

1. **Services not starting**
   ```bash
   # Check logs
   docker-compose logs service-name
   
   # Check resource usage
   docker stats
   ```

2. **Database connection issues**
   ```bash
   # Test MongoDB connection
   docker exec mongodb mongosh --eval "db.adminCommand('ping')"
   
   # Check network connectivity
   docker exec passenger-service ping mongodb
   ```

3. **Kafka connection issues**
   ```bash
   # List Kafka topics
   docker exec kafka kafka-topics --list --bootstrap-server localhost:9092
   
   # Check consumer groups
   docker exec kafka kafka-consumer-groups --bootstrap-server localhost:9092 --list
   ```

### Performance Tuning

1. **Database optimization**
   ```javascript
   // Create indexes
   db.tickets.createIndex({ "passengerId": 1, "status": 1 })
   ```

2. **Kafka optimization**
   ```bash
   # Increase partitions for high-throughput topics
   kafka-topics --alter --topic ticket.requests --partitions 6
   ```

3. **Service scaling**
   ```bash
   # Scale services based on load
   docker-compose up -d --scale passenger-service=5
   ```
