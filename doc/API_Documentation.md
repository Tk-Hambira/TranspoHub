# TranspoHub API Documentation

## Overview
This document describes the REST API endpoints for the TranspoHub distributed ticketing platform.

## Base URLs
- Passenger Service: `http://localhost:8081`
- Transport Service: `http://localhost:8082`
- Ticketing Service: `http://localhost:8083`
- Payment Service: `http://localhost:8084`
- Notification Service: `http://localhost:8085`
- Admin Service: `http://localhost:8086`

---

## Passenger Service API

### Register Passenger
**POST** `/passengers/register`

Register a new passenger account.

**Request Body:**
```json
{
  "full_name": "string",
  "email": "string",
  "password_hash": "string",
  "phone": "string (optional)"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Passenger registered",
  "id": "string"
}
```

### Passenger Login
**POST** `/passengers/login`

Authenticate a passenger.

**Request Body:**
```json
{
  "email": "string",
  "password_hash": "string"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Login successful",
  "passenger": {
    "id": "number",
    "full_name": "string",
    "email": "string"
  }
}
```

### Get Passenger Tickets
**GET** `/passengers/tickets/{passengerId}`

Get all tickets for a specific passenger.

**Response:**
```json
{
  "status": "success",
  "tickets": [
    {
      "id": "number",
      "ticket_type": "string",
      "status": "string",
      "route_name": "string",
      "origin": "string",
      "destination": "string",
      "departure_time": "string",
      "arrival_time": "string"
    }
  ]
}
```

---

## Transport Service API

### Create Route
**POST** `/transport/create`

Create a new transport route/trip.

**Request Body:**
```json
{
  "route_name": "string",
  "origin": "string",
  "destination": "string",
  "departure_time": "string (YYYY-MM-DD HH:MM:SS)",
  "arrival_time": "string (YYYY-MM-DD HH:MM:SS)",
  "vehicle_type": "string (bus|train)"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Route created successfully",
  "id": "number"
}
```

### Update Route Status
**PUT** `/transport/updateStatus`

Update the status of a transport route.

**Request Body:**
```json
{
  "id": "number",
  "status": "string (scheduled|delayed|cancelled|completed)"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Transport status updated"
}
```

### Get All Routes
**GET** `/transport/all`

Get all available transport routes.

**Response:**
```json
{
  "status": "success",
  "routes": [
    {
      "id": "number",
      "route_name": "string",
      "origin": "string",
      "destination": "string",
      "departure_time": "string",
      "arrival_time": "string",
      "vehicle_type": "string",
      "status": "string",
      "last_updated": "string"
    }
  ]
}
```

### Get Route by ID
**GET** `/transport/{id}`

Get a specific route by ID.

**Response:**
```json
{
  "status": "success",
  "route": {
    "id": "number",
    "route_name": "string",
    "origin": "string",
    "destination": "string",
    "departure_time": "string",
    "arrival_time": "string",
    "vehicle_type": "string",
    "status": "string",
    "last_updated": "string"
  }
}
```

---

## Ticketing Service API

### Create Ticket
**POST** `/tickets/create`

Create a new ticket for a passenger.

**Request Body:**
```json
{
  "passenger_id": "number",
  "transport_id": "number",
  "ticket_type": "string (single_ride|multi_ride|monthly_pass)",
  "price": "number"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Ticket created",
  "ticket_id": "number"
}
```

### Get Tickets by Passenger
**GET** `/tickets/byPassenger/{passengerId}`

Get all tickets for a specific passenger.

**Response:**
```json
{
  "status": "success",
  "tickets": [
    {
      "id": "number",
      "passenger_id": "number",
      "transport_id": "number",
      "ticket_type": "string",
      "price": "number",
      "status": "string",
      "purchased_at": "string"
    }
  ]
}
```

### Update Ticket Status
**PUT** `/tickets/updateStatus`

Update the status of a ticket.

**Request Body:**
```json
{
  "id": "number",
  "status": "string (CREATED|PAID|VALIDATED|EXPIRED)"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Ticket status updated"
}
```

### Validate Ticket
**POST** `/tickets/validate/{ticketId}`

Validate a ticket for boarding (for validators on vehicles).

**Response:**
```json
{
  "status": "success",
  "message": "Ticket validated successfully"
}
```

### Get All Tickets
**GET** `/tickets/all`

Get all tickets (admin function).

**Response:**
```json
{
  "status": "success",
  "tickets": [...]
}
```

---

## Payment Service API

### Process Payment
**POST** `/payments/pay`

Process a payment for a ticket.

**Request Body:**
```json
{
  "ticket_id": "number",
  "amount": "number",
  "method": "string (cash|card|mobile)"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Payment processed successfully",
  "payment_status": "string",
  "transaction_ref": "string",
  "payment_id": "number"
}
```

### Get Payment History
**GET** `/payments/history/{ticketId}`

Get payment history for a specific ticket.

**Response:**
```json
{
  "status": "success",
  "payments": [
    {
      "id": "number",
      "ticket_id": "number",
      "amount": "number",
      "method": "string",
      "status": "string",
      "transaction_ref": "string",
      "created_at": "string"
    }
  ]
}
```

### Get Payment by ID
**GET** `/payments/{paymentId}`

Get a specific payment by ID.

**Response:**
```json
{
  "status": "success",
  "payment": {...}
}
```

### Get All Payments
**GET** `/payments/all`

Get all payments (admin function).

### Refund Payment
**POST** `/payments/refund/{paymentId}`

Refund a payment (admin function).

**Response:**
```json
{
  "status": "success",
  "message": "Payment refunded successfully"
}
```

---

## Notification Service API

### Get Passenger Notifications
**GET** `/notifications/passenger/{passengerId}`

Get all notifications for a specific passenger.

**Response:**
```json
{
  "status": "success",
  "notifications": [
    {
      "id": "number",
      "passenger_id": "number",
      "message": "string",
      "is_read": "boolean",
      "created_at": "string"
    }
  ]
}
```

### Create Notification
**POST** `/notifications/create`

Create a new notification.

**Request Body:**
```json
{
  "passenger_id": "number (optional, null for broadcast)",
  "message": "string"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Notification created",
  "notification_id": "number"
}
```

### Mark Notification as Read
**PUT** `/notifications/markRead/{notificationId}`

Mark a notification as read.

**Response:**
```json
{
  "status": "success",
  "message": "Notification marked as read"
}
```

### Broadcast Notification
**POST** `/notifications/broadcast`

Send a broadcast notification to all passengers.

**Request Body:**
```json
{
  "message": "string"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Broadcast notification created",
  "notification_id": "number"
}
```

### Get All Notifications
**GET** `/notifications/all`

Get all notifications (admin function).

---

## Admin Service API

### Admin Login
**POST** `/admin/login`

Authenticate an admin user.

**Request Body:**
```json
{
  "username": "string",
  "password_hash": "string"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Admin login successful",
  "admin": {
    "id": "number",
    "username": "string",
    "email": "string",
    "role": "string"
  }
}
```

### Create Admin Account
**POST** `/admin/createAdmin`

Create a new admin account (super admin only).

**Request Body:**
```json
{
  "username": "string",
  "email": "string",
  "password_hash": "string",
  "role": "string (super_admin|manager|scheduler)"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Admin account created",
  "admin_id": "number"
}
```

### Get Dashboard Statistics
**GET** `/admin/dashboard`

Get system dashboard statistics.

**Response:**
```json
{
  "status": "success",
  "dashboard": {
    "total_passengers": "number",
    "total_routes": "number",
    "active_tickets": "number",
    "total_revenue": "number",
    "tickets_sold_today": "number",
    "system_alerts": "number",
    "top_routes": [...]
  }
}
```

### Create Service Disruption
**POST** `/admin/disruptions`

Create a service disruption announcement.

**Request Body:**
```json
{
  "title": "string",
  "description": "string",
  "affected_routes": ["string"],
  "severity": "string (low|medium|high|critical)"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Service disruption created",
  "disruption_id": "number"
}
```

### Get Service Disruptions
**GET** `/admin/disruptions`

Get all service disruptions.

**Response:**
```json
{
  "status": "success",
  "disruptions": [
    {
      "id": "number",
      "title": "string",
      "description": "string",
      "affected_routes": ["string"],
      "severity": "string",
      "status": "string",
      "created_at": "string",
      "resolved_at": "string"
    }
  ]
}
```

### Resolve Service Disruption
**PUT** `/admin/disruptions/{disruptionId}/resolve`

Mark a service disruption as resolved.

**Response:**
```json
{
  "status": "success",
  "message": "Service disruption resolved"
}
```

### Generate Sales Report
**GET** `/admin/reports/sales`

Generate a sales report.

**Response:**
```json
{
  "status": "success",
  "report": {
    "report_period": "string",
    "total_revenue": "number",
    "total_tickets_sold": "number",
    "avg_ticket_price": "number",
    "sales_by_route": [...],
    "sales_by_ticket_type": [...]
  }
}
```

### Generate Traffic Report
**GET** `/admin/reports/traffic`

Generate a passenger traffic report.

**Response:**
```json
{
  "status": "success",
  "report": {
    "report_period": "string",
    "total_passengers": "number",
    "peak_hours": [...],
    "busiest_routes": [...],
    "occupancy_rates": {...}
  }
}
```

---

## Error Responses

All endpoints return error responses in the following format:

```json
{
  "status": "error",
  "message": "Error description"
}
```

Common HTTP status codes:
- `200` - Success
- `400` - Bad Request (invalid input)
- `401` - Unauthorized (authentication failed)
- `404` - Not Found (resource not found)
- `500` - Internal Server Error

---

## Notes

1. **Authentication**: Currently implemented with simple password hashing. In production, implement JWT tokens or OAuth.

2. **Validation**: Input validation should be added for all endpoints.

3. **Pagination**: Large result sets should implement pagination.

4. **Rate Limiting**: Implement rate limiting for production use.

5. **CORS**: Configure CORS headers for web client integration.

6. **API Versioning**: Consider implementing API versioning (e.g., `/v1/passengers/register`).
