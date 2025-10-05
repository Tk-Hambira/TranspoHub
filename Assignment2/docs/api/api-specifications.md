# API Specifications

## Overview

This document defines the REST API specifications for all microservices in the Smart Public Transport Ticketing System.

## Common Response Format

All APIs follow a consistent response format:

```json
{
  "success": boolean,
  "data": object | array,
  "message": "string",
  "timestamp": "ISO 8601 datetime",
  "requestId": "string"
}
```

## Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "string",
    "message": "string",
    "details": "string"
  },
  "timestamp": "ISO 8601 datetime",
  "requestId": "string"
}
```

## Passenger Service API

### Base URL: `/api/v1/passengers`

#### POST /register
Register a new passenger account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+264811234567"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "passenger_id",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "phoneNumber": "+264811234567",
    "createdAt": "2025-10-04T10:00:00Z"
  }
}
```

#### POST /login
Authenticate passenger and return access token.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "accessToken": "jwt_token_here",
    "refreshToken": "refresh_token_here",
    "expiresIn": 3600,
    "passenger": {
      "id": "passenger_id",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe"
    }
  }
}
```

#### GET /{id}/profile
Get passenger profile information.

**Headers:** `Authorization: Bearer {token}`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "passenger_id",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "phoneNumber": "+264811234567",
    "createdAt": "2025-10-04T10:00:00Z",
    "updatedAt": "2025-10-04T10:00:00Z"
  }
}
```

## Transport Service API

### Base URL: `/api/v1/transport`

#### GET /routes
Get all available routes.

**Query Parameters:**
- `type` (optional): BUS | TRAIN
- `active` (optional): true | false

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "route_id",
      "name": "City Center - Airport",
      "type": "BUS",
      "stops": ["City Center", "Mall", "University", "Airport"],
      "distance": 25.5,
      "estimatedDuration": 45,
      "isActive": true
    }
  ]
}
```

#### GET /routes/{id}/trips
Get trips for a specific route.

**Query Parameters:**
- `date` (optional): YYYY-MM-DD
- `status` (optional): SCHEDULED | ACTIVE | COMPLETED | CANCELLED

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "trip_id",
      "routeId": "route_id",
      "departureTime": "2025-10-04T08:00:00Z",
      "arrivalTime": "2025-10-04T08:45:00Z",
      "capacity": 50,
      "currentOccupancy": 23,
      "status": "SCHEDULED"
    }
  ]
}
```

## Ticketing Service API

### Base URL: `/api/v1/tickets`

#### POST /purchase
Purchase a new ticket.

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "routeId": "route_id",
  "tripId": "trip_id",
  "type": "SINGLE",
  "paymentMethod": "CARD"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "ticket_id",
    "passengerId": "passenger_id",
    "routeId": "route_id",
    "tripId": "trip_id",
    "type": "SINGLE",
    "status": "CREATED",
    "amount": 15.50,
    "purchaseTime": "2025-10-04T10:00:00Z",
    "expiryTime": "2025-10-04T18:00:00Z"
  }
}
```

#### POST /{id}/validate
Validate a ticket for boarding.

**Request Body:**
```json
{
  "validatorId": "validator_device_id",
  "location": "City Center Stop"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "ticketId": "ticket_id",
    "status": "VALIDATED",
    "validationTime": "2025-10-04T08:05:00Z",
    "remainingUses": 0
  }
}
```

## Payment Service API

### Base URL: `/api/v1/payments`

#### POST /process
Process a payment for a ticket.

**Request Body:**
```json
{
  "ticketId": "ticket_id",
  "amount": 15.50,
  "paymentMethod": "CARD",
  "cardDetails": {
    "number": "****-****-****-1234",
    "expiryMonth": 12,
    "expiryYear": 2026,
    "cvv": "***"
  }
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "paymentId": "payment_id",
    "ticketId": "ticket_id",
    "amount": 15.50,
    "status": "COMPLETED",
    "transactionId": "txn_123456789",
    "processedAt": "2025-10-04T10:01:00Z"
  }
}
```

## Notification Service API

### Base URL: `/api/v1/notifications`

#### GET /passenger/{id}
Get notifications for a passenger.

**Headers:** `Authorization: Bearer {token}`

**Query Parameters:**
- `limit` (optional): number (default: 20)
- `offset` (optional): number (default: 0)
- `unreadOnly` (optional): boolean (default: false)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "notification_id",
        "type": "TICKET_VALIDATED",
        "message": "Your ticket has been validated for Route: City Center - Airport",
        "priority": "NORMAL",
        "isRead": false,
        "createdAt": "2025-10-04T08:05:00Z"
      }
    ],
    "totalCount": 15,
    "unreadCount": 3
  }
}
```

## Admin Service API

### Base URL: `/api/v1/admin`

#### GET /reports/sales
Get sales reports and analytics.

**Headers:** `Authorization: Bearer {admin_token}`

**Query Parameters:**
- `startDate`: YYYY-MM-DD
- `endDate`: YYYY-MM-DD
- `routeId` (optional): string
- `groupBy` (optional): day | week | month

**Response (200):**
```json
{
  "success": true,
  "data": {
    "totalRevenue": 12500.75,
    "totalTickets": 850,
    "averageTicketPrice": 14.71,
    "salesByRoute": [
      {
        "routeId": "route_id",
        "routeName": "City Center - Airport",
        "revenue": 5200.50,
        "ticketCount": 340
      }
    ],
    "salesByDate": [
      {
        "date": "2025-10-01",
        "revenue": 2100.25,
        "ticketCount": 145
      }
    ]
  }
}
```

## HTTP Status Codes

- `200 OK` - Successful GET, PUT requests
- `201 Created` - Successful POST requests
- `204 No Content` - Successful DELETE requests
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource conflict
- `422 Unprocessable Entity` - Validation errors
- `500 Internal Server Error` - Server errors
- `503 Service Unavailable` - Service temporarily unavailable

## Authentication

All protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer {jwt_token}
```

Tokens expire after 1 hour and can be refreshed using the refresh token endpoint.
