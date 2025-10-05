# TranspoHub Deployment Guide

## Overview
This guide provides step-by-step instructions for deploying the TranspoHub distributed ticketing platform in different environments.

---

## Development Environment

### Prerequisites
- Docker Desktop (Windows/Mac) or Docker + Docker Compose (Linux)
- Git
- 8GB RAM minimum
- 10GB free disk space

### Quick Start (Development)

1. **Clone the repository:**
```bash
git clone <repository-url>
cd TranspoHub
```

2. **Start all services:**
```bash
cd server
docker-compose up -d
```

3. **Verify deployment:**
```bash
docker-compose ps
```

4. **Check service health:**
```bash
# Test each service
curl http://localhost:8081/passengers/tickets/1
curl http://localhost:8082/transport/all
curl http://localhost:8083/tickets/all
curl http://localhost:8084/payments/all
curl http://localhost:8085/notifications/all
curl http://localhost:8086/admin/dashboard
```

5. **View logs:**
```bash
docker-compose logs -f [service-name]
```

6. **Stop services:**
```bash
docker-compose down
```

---

## Production Environment (Docker Compose)

### Server Requirements
- **CPU:** 4+ cores
- **RAM:** 16GB minimum, 32GB recommended
- **Storage:** 100GB SSD
- **Network:** 1Gbps connection
- **OS:** Ubuntu 20.04+ LTS, CentOS 8+, or RHEL 8+

### Production Setup

1. **Prepare the server:**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login to refresh group membership
```

2. **Configure production environment:**
```bash
# Create production directory
mkdir -p /opt/transpohub
cd /opt/transpohub

# Clone repository
git clone <repository-url> .

# Create production override
cp server/docker-compose.yml server/docker-compose.prod.yml
```

3. **Update production configuration:**
Edit `server/docker-compose.prod.yml`:
```yaml
version: '3.8'

services:
  mysql-db:
    image: mysql:8
    container_name: mysql-db-prod
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ticketingdb
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    ports:
      - "3308:3306"
    volumes:
      - mysql-data:/var/lib/mysql
      - ./db/schema.sql:/docker-entrypoint-initdb.d/schema.sql
      - ./db/seed.sql:/docker-entrypoint-initdb.d/seed.sql
    restart: unless-stopped
    networks:
      - transpohub-network

  kafka:
    image: apache/kafka:4.1.0
    container_name: kafka-prod
    environment:
      KAFKA_KRAFT_MODE: "true"
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@localhost:9093
    ports:
      - "9092:9092"
      - "9093:9093"
    volumes:
      - kafka-data:/var/lib/kafka/data
    restart: unless-stopped
    networks:
      - transpohub-network

  # Add similar configuration for all services...
  
networks:
  transpohub-network:
    driver: bridge

volumes:
  mysql-data:
  kafka-data:
```

4. **Create environment file:**
```bash
# Create .env file
cat > .env << EOL
MYSQL_ROOT_PASSWORD=your-strong-root-password
MYSQL_USER=transpohub
MYSQL_PASSWORD=your-strong-password
KAFKA_BOOTSTRAP_SERVERS=kafka:9092
EOL

# Secure the file
chmod 600 .env
```

5. **Deploy production services:**
```bash
cd server
docker-compose -f docker-compose.prod.yml up -d
```

6. **Set up reverse proxy (Nginx):**
```bash
# Install Nginx
sudo apt install nginx -y

# Create Nginx configuration
sudo tee /etc/nginx/sites-available/transpohub << EOL
upstream passenger_service {
    server localhost:8081;
}

upstream transport_service {
    server localhost:8082;
}

upstream ticketing_service {
    server localhost:8083;
}

upstream payment_service {
    server localhost:8084;
}

upstream notification_service {
    server localhost:8085;
}

upstream admin_service {
    server localhost:8086;
}

server {
    listen 80;
    server_name your-domain.com;

    # API Gateway routing
    location /api/passengers/ {
        proxy_pass http://passenger_service/passengers/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /api/transport/ {
        proxy_pass http://transport_service/transport/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /api/tickets/ {
        proxy_pass http://ticketing_service/tickets/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /api/payments/ {
        proxy_pass http://payment_service/payments/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /api/notifications/ {
        proxy_pass http://notification_service/notifications/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /api/admin/ {
        proxy_pass http://admin_service/admin/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOL

# Enable the site
sudo ln -s /etc/nginx/sites-available/transpohub /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

7. **Configure SSL (Let's Encrypt):**
```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Verify auto-renewal
sudo certbot renew --dry-run
```

---

## Kubernetes Deployment (Advanced)

### Prerequisites
- Kubernetes cluster (v1.20+)
- kubectl configured
- Helm 3.x (optional but recommended)

### Kubernetes Manifests

1. **Create namespace:**
```yaml
# k8s/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: transpohub
```

2. **MySQL deployment:**
```yaml
# k8s/mysql-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: transpohub
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: root-password
        - name: MYSQL_DATABASE
          value: "ticketingdb"
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
        - name: init-scripts
          mountPath: /docker-entrypoint-initdb.d
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-pvc
      - name: init-scripts
        configMap:
          name: mysql-init-scripts
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
  namespace: transpohub
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
```

3. **Kafka deployment:**
```yaml
# k8s/kafka-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kafka
  namespace: transpohub
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      containers:
      - name: kafka
        image: apache/kafka:4.1.0
        env:
        - name: KAFKA_KRAFT_MODE
          value: "true"
        - name: KAFKA_LISTENERS
          value: "PLAINTEXT://0.0.0.0:9092"
        - name: KAFKA_ADVERTISED_LISTENERS
          value: "PLAINTEXT://kafka-service:9092"
        - name: KAFKA_PROCESS_ROLES
          value: "broker,controller"
        - name: KAFKA_CONTROLLER_QUORUM_VOTERS
          value: "1@localhost:9093"
        ports:
        - containerPort: 9092
        - containerPort: 9093
        volumeMounts:
        - name: kafka-storage
          mountPath: /var/lib/kafka/data
      volumes:
      - name: kafka-storage
        persistentVolumeClaim:
          claimName: kafka-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: kafka-service
  namespace: transpohub
spec:
  selector:
    app: kafka
  ports:
  - name: kafka
    port: 9092
    targetPort: 9092
  - name: kafka-controller
    port: 9093
    targetPort: 9093
```

4. **Microservices deployment example:**
```yaml
# k8s/passenger-service.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: passenger-service
  namespace: transpohub
spec:
  replicas: 2
  selector:
    matchLabels:
      app: passenger-service
  template:
    metadata:
      labels:
        app: passenger-service
    spec:
      containers:
      - name: passenger-service
        image: transpohub/passenger-service:latest
        ports:
        - containerPort: 8081
        env:
        - name: MYSQL_HOST
          value: "mysql-service"
        - name: KAFKA_BOOTSTRAP_SERVERS
          value: "kafka-service:9092"
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /passengers/tickets/1
            port: 8081
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /passengers/tickets/1
            port: 8081
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: passenger-service
  namespace: transpohub
spec:
  selector:
    app: passenger-service
  ports:
  - port: 8081
    targetPort: 8081
  type: ClusterIP
```

5. **Deploy to Kubernetes:**
```bash
# Apply all manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -n transpohub
kubectl get services -n transpohub

# View logs
kubectl logs -f deployment/passenger-service -n transpohub
```

---

## Monitoring and Logging

### Prometheus and Grafana Setup

1. **Install Helm:**
```bash
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz
sudo mv linux-amd64/helm /usr/local/bin/
```

2. **Deploy monitoring stack:**
```bash
# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace

# Install Grafana
helm install grafana grafana/grafana -n monitoring
```

3. **Configure Grafana:**
```bash
# Get Grafana admin password
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Port forward to access Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80
```

### ELK Stack for Logging

1. **Deploy Elasticsearch:**
```bash
helm repo add elastic https://helm.elastic.co
helm install elasticsearch elastic/elasticsearch -n logging --create-namespace
```

2. **Deploy Kibana:**
```bash
helm install kibana elastic/kibana -n logging
```

3. **Deploy Filebeat:**
```bash
helm install filebeat elastic/filebeat -n logging
```

---

## Backup and Recovery

### Database Backup

1. **Automated backup script:**
```bash
#!/bin/bash
# backup-db.sh

BACKUP_DIR="/opt/transpohub/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="transpohub_backup_$DATE.sql"

mkdir -p $BACKUP_DIR

# Create database backup
docker exec mysql-db-prod mysqldump -u root -p$MYSQL_ROOT_PASSWORD ticketingdb > $BACKUP_DIR/$BACKUP_FILE

# Compress backup
gzip $BACKUP_DIR/$BACKUP_FILE

# Remove backups older than 30 days
find $BACKUP_DIR -name "*.sql.gz" -type f -mtime +30 -delete

echo "Backup completed: $BACKUP_FILE.gz"
```

2. **Schedule backups with cron:**
```bash
# Add to crontab
crontab -e

# Add line for daily backup at 2 AM
0 2 * * * /opt/transpohub/scripts/backup-db.sh
```

### Database Recovery

```bash
# Stop services
docker-compose down

# Restore database
gunzip < backup_file.sql.gz | docker exec -i mysql-db-prod mysql -u root -p$MYSQL_ROOT_PASSWORD ticketingdb

# Start services
docker-compose up -d
```

---

## Security Hardening

### SSL/TLS Configuration

1. **Generate SSL certificates:**
```bash
# For development (self-signed)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout transpohub.key -out transpohub.crt

# For production (Let's Encrypt)
certbot certonly --standalone -d your-domain.com
```

2. **Update Nginx configuration:**
```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # API routes...
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}
```

### Firewall Configuration

```bash
# Configure UFW (Ubuntu)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable

# For Docker services (allow only from specific networks)
sudo ufw allow from 172.16.0.0/12 to any port 3306
sudo ufw allow from 172.16.0.0/12 to any port 9092
```

---

## Troubleshooting

### Common Issues

1. **Services not starting:**
```bash
# Check Docker logs
docker-compose logs service-name

# Check system resources
docker stats
df -h
free -h
```

2. **Database connection issues:**
```bash
# Test MySQL connection
docker exec -it mysql-db-prod mysql -u root -p

# Check MySQL logs
docker logs mysql-db-prod
```

3. **Kafka connectivity issues:**
```bash
# Check Kafka topics
docker exec -it kafka-prod kafka-topics.sh --list --bootstrap-server localhost:9092

# Test Kafka connection
docker exec -it kafka-prod kafka-console-producer.sh --topic test --bootstrap-server localhost:9092
```

4. **Performance issues:**
```bash
# Monitor resource usage
docker stats --no-stream
htop

# Check service response times
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:8081/passengers/tickets/1
```

### Health Checks

```bash
#!/bin/bash
# health-check.sh

SERVICES=("8081" "8082" "8083" "8084" "8085" "8086")
for port in "${SERVICES[@]}"; do
    if curl -f -s http://localhost:$port/health > /dev/null; then
        echo "Service on port $port: OK"
    else
        echo "Service on port $port: FAILED"
    fi
done
```

---

## Scaling

### Horizontal Scaling (Docker Compose)

```bash
# Scale specific services
docker-compose up -d --scale passenger-service=3 --scale ticketing-service=2

# Add load balancer
docker-compose -f docker-compose.yml -f docker-compose.scale.yml up -d
```

### Auto-scaling (Kubernetes)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: passenger-service-hpa
  namespace: transpohub
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: passenger-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

---

## Migration and Updates

### Zero-downtime Updates

1. **Blue-green deployment:**
```bash
# Deploy new version (green)
docker-compose -f docker-compose.green.yml up -d

# Test green environment
./health-check.sh green

# Switch traffic to green
./switch-traffic.sh green

# Remove blue environment
docker-compose -f docker-compose.blue.yml down
```

2. **Rolling updates (Kubernetes):**
```bash
# Update deployment image
kubectl set image deployment/passenger-service passenger-service=transpohub/passenger-service:v2.0 -n transpohub

# Monitor rollout
kubectl rollout status deployment/passenger-service -n transpohub

# Rollback if needed
kubectl rollout undo deployment/passenger-service -n transpohub
```

---

## Support and Maintenance

### Regular Maintenance Tasks

1. **Weekly:**
   - Check service health
   - Review logs for errors
   - Monitor resource usage
   - Verify backups

2. **Monthly:**
   - Update security patches
   - Review performance metrics
   - Clean up old logs and backups
   - Test disaster recovery procedures

3. **Quarterly:**
   - Update dependencies
   - Security audit
   - Capacity planning review
   - Documentation updates

### Emergency Procedures

1. **Service outage:**
   - Check service status
   - Review recent changes
   - Rollback if necessary
   - Communicate with stakeholders

2. **Data loss:**
   - Stop services immediately
   - Assess damage scope
   - Restore from backup
   - Verify data integrity

3. **Security incident:**
   - Isolate affected systems
   - Preserve evidence
   - Patch vulnerabilities
   - Review security policies

---

## Contact Information

- **DevOps Team:** devops@transpohub.com
- **Emergency Hotline:** +264-XXX-XXXX
- **Documentation:** https://docs.transpohub.com
- **Status Page:** https://status.transpohub.com
