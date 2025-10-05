# Database Schema Design

## Overview

The Smart Public Transport Ticketing System uses MongoDB as the primary database. Each microservice has its own database following the database-per-service pattern.

## Database Structure

### Passenger Service Database: `passenger_db`

#### Collection: `passengers`
```javascript
{
  _id: ObjectId,
  email: String, // unique index
  password: String, // bcrypt hashed
  firstName: String,
  lastName: String,
  phoneNumber: String,
  isActive: Boolean,
  createdAt: Date,
  updatedAt: Date
}

// Indexes
db.passengers.createIndex({ "email": 1 }, { unique: true })
db.passengers.createIndex({ "phoneNumber": 1 })
db.passengers.createIndex({ "createdAt": 1 })
```

#### Collection: `passenger_sessions`
```javascript
{
  _id: ObjectId,
  passengerId: ObjectId,
  accessToken: String,
  refreshToken: String,
  expiresAt: Date,
  isActive: Boolean,
  createdAt: Date
}

// Indexes
db.passenger_sessions.createIndex({ "passengerId": 1 })
db.passenger_sessions.createIndex({ "accessToken": 1 })
db.passenger_sessions.createIndex({ "expiresAt": 1 }, { expireAfterSeconds: 0 })
```

### Transport Service Database: `transport_db`

#### Collection: `routes`
```javascript
{
  _id: ObjectId,
  name: String,
  type: String, // "BUS" | "TRAIN"
  stops: [String],
  distance: Number, // in kilometers
  estimatedDuration: Number, // in minutes
  basePrice: Number,
  isActive: Boolean,
  createdAt: Date,
  updatedAt: Date
}

// Indexes
db.routes.createIndex({ "name": 1 })
db.routes.createIndex({ "type": 1 })
db.routes.createIndex({ "isActive": 1 })
```

#### Collection: `trips`
```javascript
{
  _id: ObjectId,
  routeId: ObjectId,
  departureTime: Date,
  arrivalTime: Date,
  capacity: Number,
  currentOccupancy: Number,
  status: String, // "SCHEDULED" | "ACTIVE" | "COMPLETED" | "CANCELLED"
  vehicleId: String,
  driverId: String,
  createdAt: Date,
  updatedAt: Date
}

// Indexes
db.trips.createIndex({ "routeId": 1 })
db.trips.createIndex({ "departureTime": 1 })
db.trips.createIndex({ "status": 1 })
db.trips.createIndex({ "routeId": 1, "departureTime": 1 })
```

#### Collection: `schedules`
```javascript
{
  _id: ObjectId,
  routeId: ObjectId,
  dayOfWeek: Number, // 0-6 (Sunday-Saturday)
  departureTimes: [String], // ["08:00", "10:00", "12:00"]
  isActive: Boolean,
  effectiveFrom: Date,
  effectiveTo: Date,
  createdAt: Date
}

// Indexes
db.schedules.createIndex({ "routeId": 1 })
db.schedules.createIndex({ "dayOfWeek": 1 })
db.schedules.createIndex({ "effectiveFrom": 1, "effectiveTo": 1 })
```

### Ticketing Service Database: `ticketing_db`

#### Collection: `tickets`
```javascript
{
  _id: ObjectId,
  passengerId: ObjectId,
  routeId: ObjectId,
  tripId: ObjectId,
  type: String, // "SINGLE" | "MULTIPLE" | "PASS"
  status: String, // "CREATED" | "PAID" | "VALIDATED" | "EXPIRED"
  amount: Number,
  remainingUses: Number, // for MULTIPLE tickets
  purchaseTime: Date,
  validationTime: Date,
  expiryTime: Date,
  validationLocation: String,
  validatorId: String,
  createdAt: Date,
  updatedAt: Date
}

// Indexes
db.tickets.createIndex({ "passengerId": 1 })
db.tickets.createIndex({ "routeId": 1 })
db.tickets.createIndex({ "tripId": 1 })
db.tickets.createIndex({ "status": 1 })
db.tickets.createIndex({ "purchaseTime": 1 })
db.tickets.createIndex({ "expiryTime": 1 })
db.tickets.createIndex({ "passengerId": 1, "status": 1 })
```

#### Collection: `ticket_types`
```javascript
{
  _id: ObjectId,
  name: String, // "Single Ride", "Day Pass", "Weekly Pass"
  type: String, // "SINGLE" | "MULTIPLE" | "PASS"
  validityPeriod: Number, // in hours
  maxUses: Number, // -1 for unlimited
  priceMultiplier: Number, // multiplier of base route price
  isActive: Boolean,
  createdAt: Date
}

// Indexes
db.ticket_types.createIndex({ "type": 1 })
db.ticket_types.createIndex({ "isActive": 1 })
```

### Payment Service Database: `payment_db`

#### Collection: `payments`
```javascript
{
  _id: ObjectId,
  ticketId: ObjectId,
  passengerId: ObjectId,
  amount: Number,
  currency: String, // "NAD"
  status: String, // "PENDING" | "COMPLETED" | "FAILED" | "REFUNDED"
  paymentMethod: String, // "CARD" | "MOBILE" | "CASH"
  transactionId: String, // external payment gateway transaction ID
  gatewayResponse: Object, // payment gateway response
  processedAt: Date,
  refundedAt: Date,
  refundAmount: Number,
  createdAt: Date,
  updatedAt: Date
}

// Indexes
db.payments.createIndex({ "ticketId": 1 })
db.payments.createIndex({ "passengerId": 1 })
db.payments.createIndex({ "status": 1 })
db.payments.createIndex({ "transactionId": 1 })
db.payments.createIndex({ "processedAt": 1 })
```

#### Collection: `payment_methods`
```javascript
{
  _id: ObjectId,
  passengerId: ObjectId,
  type: String, // "CARD" | "MOBILE"
  cardLast4: String, // for card payments
  cardBrand: String, // "VISA" | "MASTERCARD"
  mobileNumber: String, // for mobile payments
  isDefault: Boolean,
  isActive: Boolean,
  createdAt: Date
}

// Indexes
db.payment_methods.createIndex({ "passengerId": 1 })
db.payment_methods.createIndex({ "passengerId": 1, "isDefault": 1 })
```

### Notification Service Database: `notification_db`

#### Collection: `notifications`
```javascript
{
  _id: ObjectId,
  recipientId: ObjectId,
  recipientType: String, // "PASSENGER" | "ADMIN"
  type: String, // "TICKET_VALIDATED" | "SCHEDULE_UPDATE" | "PAYMENT_CONFIRMED"
  title: String,
  message: String,
  priority: String, // "LOW" | "NORMAL" | "HIGH" | "URGENT"
  isRead: Boolean,
  readAt: Date,
  deliveryStatus: String, // "PENDING" | "SENT" | "DELIVERED" | "FAILED"
  channels: [String], // ["EMAIL", "SMS", "PUSH"]
  metadata: Object, // additional context data
  createdAt: Date,
  updatedAt: Date
}

// Indexes
db.notifications.createIndex({ "recipientId": 1 })
db.notifications.createIndex({ "type": 1 })
db.notifications.createIndex({ "isRead": 1 })
db.notifications.createIndex({ "priority": 1 })
db.notifications.createIndex({ "createdAt": 1 })
db.notifications.createIndex({ "recipientId": 1, "isRead": 1 })
```

#### Collection: `notification_templates`
```javascript
{
  _id: ObjectId,
  type: String,
  channel: String, // "EMAIL" | "SMS" | "PUSH"
  subject: String,
  template: String, // template with placeholders
  isActive: Boolean,
  createdAt: Date
}

// Indexes
db.notification_templates.createIndex({ "type": 1, "channel": 1 })
```

### Admin Service Database: `admin_db`

#### Collection: `admin_users`
```javascript
{
  _id: ObjectId,
  username: String,
  email: String,
  password: String, // bcrypt hashed
  firstName: String,
  lastName: String,
  role: String, // "ADMIN" | "OPERATOR" | "VIEWER"
  permissions: [String],
  isActive: Boolean,
  lastLoginAt: Date,
  createdAt: Date,
  updatedAt: Date
}

// Indexes
db.admin_users.createIndex({ "username": 1 }, { unique: true })
db.admin_users.createIndex({ "email": 1 }, { unique: true })
db.admin_users.createIndex({ "role": 1 })
```

#### Collection: `service_disruptions`
```javascript
{
  _id: ObjectId,
  routeId: ObjectId,
  title: String,
  description: String,
  severity: String, // "LOW" | "MEDIUM" | "HIGH" | "CRITICAL"
  status: String, // "ACTIVE" | "RESOLVED" | "SCHEDULED"
  affectedTrips: [ObjectId],
  startTime: Date,
  endTime: Date,
  createdBy: ObjectId,
  createdAt: Date,
  updatedAt: Date
}

// Indexes
db.service_disruptions.createIndex({ "routeId": 1 })
db.service_disruptions.createIndex({ "status": 1 })
db.service_disruptions.createIndex({ "severity": 1 })
db.service_disruptions.createIndex({ "startTime": 1, "endTime": 1 })
```

## Data Consistency Strategy

### Eventual Consistency
- Cross-service data synchronization through Kafka events
- Compensation patterns for failed transactions
- Idempotent event processing

### Strong Consistency
- Within-service transactions using MongoDB transactions
- Critical operations like payment processing
- Ticket validation to prevent double-spending

## Backup and Recovery

### Backup Strategy
- Daily automated backups of all databases
- Point-in-time recovery capability
- Cross-region backup replication

### Recovery Procedures
- Automated failover for database clusters
- Data restoration procedures
- Disaster recovery testing

## Performance Optimization

### Indexing Strategy
- Compound indexes for common query patterns
- Partial indexes for filtered queries
- TTL indexes for temporary data

### Sharding Strategy
- Shard tickets collection by passengerId
- Shard notifications by recipientId
- Route-based sharding for transport data

### Caching Strategy
- Redis cache for frequently accessed data
- Cache invalidation through Kafka events
- Session caching for authentication
