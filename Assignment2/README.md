# Smart Public Transport Ticketing System

A distributed smart public transport ticketing system for buses and trains, built with microservices architecture using Ballerina, Kafka, MongoDB, and Docker.

## Overview

This system provides a modern, scalable solution for public transport ticketing that supports:
- **Passengers**: Account management, ticket purchasing, route browsing, and real-time notifications
- **Administrators**: Route/trip management, sales monitoring, and service disruption publishing
- **Validators**: Ticket validation on vehicles

## Architecture

The system follows a microservices architecture with event-driven communication:

### Core Services
1. **Passenger Service** - User registration, authentication, and account management
2. **Transport Service** - Route and trip management, schedule updates
3. **Ticketing Service** - Ticket lifecycle management and processing
4. **Payment Service** - Payment processing and transaction management
5. **Notification Service** - Real-time notifications and alerts
6. **Admin Service** - Administrative functions and reporting

### Technology Stack
- **Backend**: Ballerina
- **Message Broker**: Apache Kafka
- **Database**: MongoDB
- **Containerization**: Docker
- **Orchestration**: Docker Compose
- **API**: RESTful services with event-driven communication

## Project Structure

```
├── services/
│   ├── passenger-service/
│   ├── transport-service/
│   ├── ticketing-service/
│   ├── payment-service/
│   ├── notification-service/
│   └── admin-service/
├── infrastructure/
│   ├── kafka/
│   ├── mongodb/
│   └── docker/
├── docs/
│   ├── api/
│   ├── architecture/
│   └── deployment/
├── tests/
└── docker-compose.yml
```

## Getting Started

### Prerequisites
- Docker and Docker Compose
- Ballerina (latest version)
- Java 11 or higher

### Quick Start
1. Clone the repository
2. Run `docker-compose up -d` to start infrastructure services
3. Build and run individual services using Ballerina

## Development

Each service is independently deployable and follows the same structure:
- `main.bal` - Service entry point
- `types.bal` - Data types and models
- `service.bal` - HTTP service implementation
- `kafka.bal` - Kafka producers/consumers
- `database.bal` - Database operations

## Event-Driven Architecture

The system uses Kafka topics for asynchronous communication:
- `ticket.requests` - Ticket purchase requests
- `payments.processed` - Payment confirmations
- `schedule.updates` - Route and trip changes
- `notifications.send` - Notification events
- `tickets.validated` - Ticket validation events

## Contributing

This is a group project for DSA612S. All group members should contribute code and have commits in the repository.

## License

Academic project for Namibia University of Science and Technology.