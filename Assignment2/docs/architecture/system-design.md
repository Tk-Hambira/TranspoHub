# System Architecture Design

## Overview

The Smart Public Transport Ticketing System is designed as a distributed microservices architecture that provides scalable, fault-tolerant, and maintainable solution for public transport ticketing.

## Architecture Principles

1. **Microservices Architecture**: Each service has a single responsibility and can be deployed independently
2. **Event-Driven Communication**: Services communicate asynchronously through Kafka events
3. **Database Per Service**: Each service manages its own data store
4. **API Gateway Pattern**: Centralized entry point for client requests
5. **Circuit Breaker Pattern**: Fault tolerance and resilience
6. **CQRS**: Command Query Responsibility Segregation for complex operations

## System Components

### Core Services

#### 1. Passenger Service
- **Responsibility**: User management, authentication, and passenger profiles
- **Database**: MongoDB collection for user data
- **APIs**: 
  - POST /passengers/register
  - POST /passengers/login
  - GET /passengers/{id}/profile
  - PUT /passengers/{id}/profile
  - GET /passengers/{id}/tickets

#### 2. Transport Service
- **Responsibility**: Route and trip management, schedule maintenance
- **Database**: MongoDB collections for routes, trips, schedules
- **APIs**:
  - GET /routes
  - POST /routes
  - GET /routes/{id}/trips
  - POST /trips
  - PUT /trips/{id}/schedule

#### 3. Ticketing Service
- **Responsibility**: Ticket lifecycle management, validation
- **Database**: MongoDB collection for tickets
- **APIs**:
  - POST /tickets/purchase
  - GET /tickets/{id}
  - POST /tickets/{id}/validate
  - GET /tickets/passenger/{passengerId}

#### 4. Payment Service
- **Responsibility**: Payment processing, transaction management
- **Database**: MongoDB collection for transactions
- **APIs**:
  - POST /payments/process
  - GET /payments/{id}/status
  - POST /payments/{id}/refund

#### 5. Notification Service
- **Responsibility**: Real-time notifications and alerts
- **Database**: MongoDB collection for notification history
- **APIs**:
  - POST /notifications/send
  - GET /notifications/passenger/{id}

#### 6. Admin Service
- **Responsibility**: Administrative functions, reporting, analytics
- **Database**: Aggregated data from other services
- **APIs**:
  - GET /admin/reports/sales
  - GET /admin/reports/usage
  - POST /admin/disruptions
  - GET /admin/analytics/dashboard

## Event-Driven Architecture

### Kafka Topics

1. **ticket.requests**
   - Producer: Ticketing Service
   - Consumer: Payment Service
   - Schema: {ticketId, passengerId, routeId, amount, timestamp}

2. **payments.processed**
   - Producer: Payment Service
   - Consumer: Ticketing Service, Notification Service
   - Schema: {paymentId, ticketId, status, amount, timestamp}

3. **schedule.updates**
   - Producer: Transport Service
   - Consumer: Notification Service, Admin Service
   - Schema: {routeId, tripId, updateType, newSchedule, timestamp}

4. **notifications.send**
   - Producer: Multiple Services
   - Consumer: Notification Service
   - Schema: {recipientId, type, message, priority, timestamp}

5. **tickets.validated**
   - Producer: Ticketing Service
   - Consumer: Admin Service, Transport Service
   - Schema: {ticketId, passengerId, routeId, validationTime, location}

## Data Models

### Passenger
```json
{
  "_id": "ObjectId",
  "email": "string",
  "password": "string (hashed)",
  "firstName": "string",
  "lastName": "string",
  "phoneNumber": "string",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

### Route
```json
{
  "_id": "ObjectId",
  "name": "string",
  "type": "BUS|TRAIN",
  "stops": ["string"],
  "distance": "number",
  "estimatedDuration": "number",
  "isActive": "boolean"
}
```

### Trip
```json
{
  "_id": "ObjectId",
  "routeId": "ObjectId",
  "departureTime": "datetime",
  "arrivalTime": "datetime",
  "capacity": "number",
  "currentOccupancy": "number",
  "status": "SCHEDULED|ACTIVE|COMPLETED|CANCELLED"
}
```

### Ticket
```json
{
  "_id": "ObjectId",
  "passengerId": "ObjectId",
  "routeId": "ObjectId",
  "tripId": "ObjectId",
  "type": "SINGLE|MULTIPLE|PASS",
  "status": "CREATED|PAID|VALIDATED|EXPIRED",
  "purchaseTime": "datetime",
  "validationTime": "datetime",
  "expiryTime": "datetime",
  "amount": "number"
}
```

### Payment
```json
{
  "_id": "ObjectId",
  "ticketId": "ObjectId",
  "passengerId": "ObjectId",
  "amount": "number",
  "status": "PENDING|COMPLETED|FAILED|REFUNDED",
  "paymentMethod": "CARD|MOBILE|CASH",
  "transactionId": "string",
  "processedAt": "datetime"
}
```

## Deployment Architecture

### Container Strategy
- Each service runs in its own Docker container
- Infrastructure services (Kafka, MongoDB) in separate containers
- Docker Compose for local development
- Kubernetes for production deployment

### Scaling Strategy
- Horizontal scaling for stateless services
- Database sharding for high-volume data
- Kafka partitioning for message distribution
- Load balancing with health checks

## Security Considerations

1. **Authentication**: JWT tokens for service-to-service communication
2. **Authorization**: Role-based access control (RBAC)
3. **Data Encryption**: TLS for data in transit, encryption at rest
4. **API Security**: Rate limiting, input validation, CORS policies
5. **Network Security**: Service mesh for internal communication

## Monitoring and Observability

1. **Logging**: Centralized logging with correlation IDs
2. **Metrics**: Service metrics, business metrics, infrastructure metrics
3. **Tracing**: Distributed tracing for request flows
4. **Health Checks**: Service health endpoints
5. **Alerting**: Automated alerts for system issues

## Fault Tolerance

1. **Circuit Breakers**: Prevent cascade failures
2. **Retry Logic**: Exponential backoff for transient failures
3. **Bulkhead Pattern**: Isolate critical resources
4. **Graceful Degradation**: Fallback mechanisms
5. **Data Consistency**: Eventual consistency with compensation patterns
