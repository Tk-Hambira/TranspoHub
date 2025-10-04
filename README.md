# TranspoHub
This is a modern distributed ticketing platform for buses and trains. The system is dsesigned for the Windhoek City that supports different user roles (passengers, transport administrators, and validators on vehicles) and provide a seamless experience across devices.

The platform replaces traditional paper ticketing systems with a real-time, event-driven, and fault-tolerant architecture built using Ballerina, Kafka, and MySQL.

Objectives:
 The goal of this project is to:
  Design and implement microservices with clear boundaries and APIs.
  Use Kafka for event-driven communication between services.
  Store and manage persistent data using MySQL.
  Containerize each service using Docker and orchestrate with Docker Compose.
  Demonstrate scalability, fault-tolerance, and resilience.

System Features:
 Passenger Features
 Register and log in securely.
 Browse available routes, trips, and schedules.
 Purchase tickets (single, multiple, or pass).
 Validate tickets during boarding.
 Receive real time notifications on route disruptions or delays.

Administrator Features
 Manage routes and trip schedules.
 Monitor ticket sales and passenger traffic.
 Publish service disruptions and schedule updates.
 Generate reports for operational insights.

System Features
 Event-driven messaging using Kafka.
 Persistent storage in MySQL.
 Deployed and orchestrated via Docker Compose.
 Scalable and fault-tolerant under high concurrency.
