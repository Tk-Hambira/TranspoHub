# TranspoHub
This is a modern distributed ticketing platform for buses and trains. The system is designed for the Windhoek City that supports different user roles (passengers, transport administrators, and validators on vehicles) and provide a seamless experience across devices.

The platform replaces traditional paper ticketing systems with a real-time, event-driven, and fault-tolerant architecture built using Ballerina, Kafka, and MySQL.

---

## Objectives:
**The goal of this project is to:**
- Design and implement microservices with clear boundaries and APIs.
- Use Kafka for event-driven communication between services.
- Store and manage persistent data using MySQL.
- Containerize each service using Docker and orchestrate with Docker Compose.
- Demonstrate scalability, fault-tolerance, and resilience.

## System Features:

### Passenger Features
- Register and log in securely.
- Browse available routes, trips, and schedules.
- Purchase tickets (single, multiple, or pass).
- Validate tickets during boarding.
- Receive real time notifications on route disruptions or delays.

### Administrator Features
- Manage routes and trip schedules.
- Monitor ticket sales and passenger traffic.
- Publish service disruptions and schedule updates.
- Generate reports for operational insights.

### System Features
- Event-driven messaging using Kafka.
- Persistent storage in MySQL.
- Deployed and orchestrated via Docker Compose.
- Scalable and fault-tolerant under high concurrency.

---

## Architecture

### Microservices Architecture
The system consists of 6 microservices:

1. **Passenger Service** (Port 8081)
   - User registration and authentication
   - Passenger profile management
   - Ticket history retrieval

2. **Transport Service** (Port 8082)
   - Route and trip management
   - Schedule creation and updates
   - Status management (scheduled, delayed, cancelled, completed)

3. **Ticketing Service** (Port 8083)
   - Ticket creation and management
   - Ticket status updates (CREATED, PAID, VALIDATED, EXPIRED)
   - Ticket validation for validators

4. **Payment Service** (Port 8084)
   - Payment processing simulation
   - Payment method support (cash, card, mobile)
   - Payment status tracking and refunds

5. **Notification Service** (Port 8085)
   - Real-time notification delivery
   - Broadcast messaging
   - Notification management

6. **Admin Service** (Port 8086)
   - Admin authentication and management
   - Service disruption announcements
   - Dashboard statistics and reports

### Database Schema
MySQL database (`ticketingdb`) with tables:
- `passengers` - User information and authentication
- `transport` - Routes, schedules, and trip information
- `tickets` - Ticket records with types (single_ride, multi_ride, monthly_pass)
- `payments` - Payment transactions and status
- `notifications` - User notification system
- `admins` - Administrative user management

### Event-Driven Communication
**Kafka Topics (Planned):**
- `ticket.requests` - Ticket creation requests
- `ticket.events` - Ticket lifecycle events
- `schedule.updates` - Transport schedule changes
- `payment.confirmations` - Payment status updates
- `notifications` - Real-time notifications

---

## Technology Stack
- **Backend Framework:** Ballerina (microservices and integration)
- **Database:** MySQL 8.0
- **Message Broker:** Apache Kafka 4.1.0
- **Containerization:** Docker with Docker Compose
- **Architecture Pattern:** Event-driven microservices

---

## Getting Started

### Prerequisites
- Docker and Docker Compose
- Ballerina Swan Lake (2201.10.0 or later)
- Git

### Installation & Setup

1. **Clone the repository:**
```bash
git clone <repository-url>
cd TranspoHub
```

2. **Start the infrastructure services:**
```bash
cd server
docker-compose up mysql-db kafka -d
```

3. **Wait for services to be ready (about 30 seconds), then start the microservices:**
```bash
docker-compose up -d
```

4. **Verify all services are running:**
```bash
docker-compose ps
```

### Service Endpoints

#### Passenger Service (http://localhost:8081)
- `POST /passengers/register` - Register new passenger
- `POST /passengers/login` - Passenger login
- `GET /passengers/tickets/{passengerId}` - Get passenger tickets

#### Transport Service (http://localhost:8082)
- `POST /transport/create` - Create new route/trip
- `PUT /transport/updateStatus` - Update route status
- `GET /transport/all` - Get all routes
- `GET /transport/{id}` - Get route by ID

#### Ticketing Service (http://localhost:8083)
- `POST /tickets/create` - Create new ticket
- `GET /tickets/byPassenger/{passengerId}` - Get tickets by passenger
- `PUT /tickets/updateStatus` - Update ticket status
- `POST /tickets/validate/{ticketId}` - Validate ticket
- `GET /tickets/all` - Get all tickets

#### Payment Service (http://localhost:8084)
- `POST /payments/pay` - Process payment
- `GET /payments/history/{ticketId}` - Get payment history
- `GET /payments/{paymentId}` - Get payment by ID
- `GET /payments/all` - Get all payments
- `POST /payments/refund/{paymentId}` - Refund payment

#### Notification Service (http://localhost:8085)
- `GET /notifications/passenger/{passengerId}` - Get passenger notifications
- `POST /notifications/create` - Create notification
- `PUT /notifications/markRead/{notificationId}` - Mark as read
- `POST /notifications/broadcast` - Broadcast to all
- `GET /notifications/all` - Get all notifications

#### Admin Service (http://localhost:8086)
- `POST /admin/login` - Admin login
- `POST /admin/createAdmin` - Create admin account
- `GET /admin/dashboard` - Get dashboard statistics
- `POST /admin/disruptions` - Create service disruption
- `GET /admin/disruptions` - Get all disruptions
- `PUT /admin/disruptions/{id}/resolve` - Resolve disruption
- `GET /admin/reports/sales` - Generate sales report
- `GET /admin/reports/traffic` - Generate traffic report

---

## API Examples

### Register a Passenger
```bash
curl -X POST http://localhost:8081/passengers/register \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "John Doe",
    "email": "john@example.com", 
    "password_hash": "hashed_password",
    "phone": "+264123456789"
  }'
```

### Create a Route
```bash
curl -X POST http://localhost:8082/transport/create \
  -H "Content-Type: application/json" \
  -d '{
    "route_name": "Downtown Express",
    "origin": "Windhoek Central",
    "destination": "Katutura",
    "departure_time": "2025-10-06 08:30:00",
    "arrival_time": "2025-10-06 09:10:00",
    "vehicle_type": "bus"
  }'
```

### Purchase a Ticket
```bash
curl -X POST http://localhost:8083/tickets/create \
  -H "Content-Type: application/json" \
  -d '{
    "passenger_id": 1,
    "transport_id": 1,
    "ticket_type": "single_ride",
    "price": 50.00
  }'
```

### Process Payment
```bash
curl -X POST http://localhost:8084/payments/pay \
  -H "Content-Type: application/json" \
  -d '{
    "ticket_id": 1,
    "amount": 50.00,
    "method": "card"
  }'
```

---

## Development

### Current Implementation Status
 **Completed:**
- All 6 microservices implemented
- Docker containerization
- Database schema and seed data
- Docker Compose configuration
- API endpoints for all major functionality
- Mock data implementation for testing

**Pending (for production):**
- Actual MySQL/Kafka integration (currently using mock data)
- Inter-service communication via Kafka
- Authentication and authorization
- Input validation and error handling
- API documentation (OpenAPI/Swagger)
- Unit and integration tests
- Client application (web/mobile)
- Logging and monitoring
- Load balancing and scaling

### Mock Data vs Production
Currently, all services use in-memory mock data for rapid development and testing. In production:
- Replace mock databases with actual MySQL connections
- Implement Kafka producers/consumers
- Add persistent storage
- Implement proper error handling

### Building Individual Services
```bash
cd server/passenger-service
bal build
bal run
```

### Database Initialization
The database schema and seed data are automatically loaded when MySQL container starts.

---

## Testing

### Health Check
```bash
# Check if all services are responding
curl http://localhost:8081/passengers/tickets/1
curl http://localhost:8082/transport/all
curl http://localhost:8083/tickets/all
curl http://localhost:8084/payments/all
curl http://localhost:8085/notifications/all
curl http://localhost:8086/admin/dashboard
```

### End-to-End Workflow
1. Register a passenger
2. Create transport routes
3. Purchase tickets
4. Process payments
5. Validate tickets
6. Send notifications
7. Generate reports

---

## Deployment

### Docker Compose (Development)
```bash
docker-compose up -d
```

### Kubernetes (Production - Future)
```bash
kubectl apply -f k8s/
```

---

## Troubleshooting

### Common Issues
1. **Port conflicts:** Ensure ports 8081-8086, 3308, 9092-9093 are available
2. **Database connection:** Wait for MySQL to fully initialize before starting services
3. **Kafka connectivity:** Ensure Kafka is running before starting dependent services

### Logs
```bash
docker-compose logs [service-name]
```

### Restart Services
```bash
docker-compose restart [service-name]
```

---

## Contributing
1. Fork the repository
2. Create feature branch
3. Commit changes
4. Create pull request

## License
MIT License

## Contact
For questions and support, please contact the development team.
