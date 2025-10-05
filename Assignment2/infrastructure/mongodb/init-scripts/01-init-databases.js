// MongoDB initialization script for Smart Public Transport Ticketing System
// This script creates databases and collections with proper indexes

// Switch to admin database for authentication
db = db.getSiblingDB('admin');

// Create databases and users for each microservice
const databases = [
  'passenger_db',
  'transport_db', 
  'ticketing_db',
  'payment_db',
  'notification_db',
  'admin_db'
];

databases.forEach(dbName => {
  print(`Creating database: ${dbName}`);
  
  // Switch to the database
  db = db.getSiblingDB(dbName);
  
  // Create a user for this database
  db.createUser({
    user: `${dbName}_user`,
    pwd: 'service_password_123',
    roles: [
      { role: 'readWrite', db: dbName },
      { role: 'dbAdmin', db: dbName }
    ]
  });
  
  print(`Created user for database: ${dbName}`);
});

// Initialize Passenger Service Database
print('Initializing Passenger Service Database...');
db = db.getSiblingDB('passenger_db');

// Create passengers collection with indexes
db.createCollection('passengers');
db.passengers.createIndex({ "email": 1 }, { unique: true });
db.passengers.createIndex({ "phoneNumber": 1 });
db.passengers.createIndex({ "createdAt": 1 });

// Create passenger_sessions collection with indexes
db.createCollection('passenger_sessions');
db.passenger_sessions.createIndex({ "passengerId": 1 });
db.passenger_sessions.createIndex({ "accessToken": 1 });
db.passenger_sessions.createIndex({ "expiresAt": 1 }, { expireAfterSeconds: 0 });

print('Passenger Service Database initialized');

// Initialize Transport Service Database
print('Initializing Transport Service Database...');
db = db.getSiblingDB('transport_db');

// Create routes collection with indexes
db.createCollection('routes');
db.routes.createIndex({ "name": 1 });
db.routes.createIndex({ "type": 1 });
db.routes.createIndex({ "isActive": 1 });

// Create trips collection with indexes
db.createCollection('trips');
db.trips.createIndex({ "routeId": 1 });
db.trips.createIndex({ "departureTime": 1 });
db.trips.createIndex({ "status": 1 });
db.trips.createIndex({ "routeId": 1, "departureTime": 1 });

// Create schedules collection with indexes
db.createCollection('schedules');
db.schedules.createIndex({ "routeId": 1 });
db.schedules.createIndex({ "dayOfWeek": 1 });
db.schedules.createIndex({ "effectiveFrom": 1, "effectiveTo": 1 });

// Insert sample routes
db.routes.insertMany([
  {
    name: "City Center - Airport",
    type: "BUS",
    stops: ["City Center", "Shopping Mall", "University", "Airport"],
    distance: 25.5,
    estimatedDuration: 45,
    basePrice: 15.50,
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: "Windhoek Central - Katutura",
    type: "BUS", 
    stops: ["Windhoek Central", "Khomasdal", "Goreangab", "Katutura"],
    distance: 18.2,
    estimatedDuration: 35,
    basePrice: 12.00,
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: "Windhoek - Rehoboth Express",
    type: "TRAIN",
    stops: ["Windhoek Station", "Dordabis", "Rehoboth Station"],
    distance: 90.0,
    estimatedDuration: 120,
    basePrice: 35.00,
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date()
  }
]);

print('Transport Service Database initialized with sample data');

// Initialize Ticketing Service Database
print('Initializing Ticketing Service Database...');
db = db.getSiblingDB('ticketing_db');

// Create tickets collection with indexes
db.createCollection('tickets');
db.tickets.createIndex({ "passengerId": 1 });
db.tickets.createIndex({ "routeId": 1 });
db.tickets.createIndex({ "tripId": 1 });
db.tickets.createIndex({ "status": 1 });
db.tickets.createIndex({ "purchaseTime": 1 });
db.tickets.createIndex({ "expiryTime": 1 });
db.tickets.createIndex({ "passengerId": 1, "status": 1 });

// Create ticket_types collection with indexes
db.createCollection('ticket_types');
db.ticket_types.createIndex({ "type": 1 });
db.ticket_types.createIndex({ "isActive": 1 });

// Insert ticket types
db.ticket_types.insertMany([
  {
    name: "Single Ride",
    type: "SINGLE",
    validityPeriod: 4, // 4 hours
    maxUses: 1,
    priceMultiplier: 1.0,
    isActive: true,
    createdAt: new Date()
  },
  {
    name: "Day Pass",
    type: "PASS",
    validityPeriod: 24, // 24 hours
    maxUses: -1, // unlimited
    priceMultiplier: 3.0,
    isActive: true,
    createdAt: new Date()
  },
  {
    name: "Weekly Pass",
    type: "PASS",
    validityPeriod: 168, // 7 days * 24 hours
    maxUses: -1, // unlimited
    priceMultiplier: 15.0,
    isActive: true,
    createdAt: new Date()
  }
]);

print('Ticketing Service Database initialized with sample data');

// Initialize Payment Service Database
print('Initializing Payment Service Database...');
db = db.getSiblingDB('payment_db');

// Create payments collection with indexes
db.createCollection('payments');
db.payments.createIndex({ "ticketId": 1 });
db.payments.createIndex({ "passengerId": 1 });
db.payments.createIndex({ "status": 1 });
db.payments.createIndex({ "transactionId": 1 });
db.payments.createIndex({ "processedAt": 1 });

// Create payment_methods collection with indexes
db.createCollection('payment_methods');
db.payment_methods.createIndex({ "passengerId": 1 });
db.payment_methods.createIndex({ "passengerId": 1, "isDefault": 1 });

print('Payment Service Database initialized');

// Initialize Notification Service Database
print('Initializing Notification Service Database...');
db = db.getSiblingDB('notification_db');

// Create notifications collection with indexes
db.createCollection('notifications');
db.notifications.createIndex({ "recipientId": 1 });
db.notifications.createIndex({ "type": 1 });
db.notifications.createIndex({ "isRead": 1 });
db.notifications.createIndex({ "priority": 1 });
db.notifications.createIndex({ "createdAt": 1 });
db.notifications.createIndex({ "recipientId": 1, "isRead": 1 });

// Create notification_templates collection with indexes
db.createCollection('notification_templates');
db.notification_templates.createIndex({ "type": 1, "channel": 1 });

// Insert notification templates
db.notification_templates.insertMany([
  {
    type: "TICKET_VALIDATED",
    channel: "PUSH",
    subject: "Ticket Validated",
    template: "Your ticket for {{routeName}} has been validated at {{location}}",
    isActive: true,
    createdAt: new Date()
  },
  {
    type: "PAYMENT_CONFIRMED",
    channel: "EMAIL",
    subject: "Payment Confirmation",
    template: "Your payment of {{amount}} NAD for ticket {{ticketId}} has been confirmed",
    isActive: true,
    createdAt: new Date()
  },
  {
    type: "SCHEDULE_UPDATE",
    channel: "PUSH",
    subject: "Schedule Update",
    template: "Route {{routeName}} schedule has been updated. New departure time: {{newTime}}",
    isActive: true,
    createdAt: new Date()
  }
]);

print('Notification Service Database initialized with sample data');

// Initialize Admin Service Database
print('Initializing Admin Service Database...');
db = db.getSiblingDB('admin_db');

// Create admin_users collection with indexes
db.createCollection('admin_users');
db.admin_users.createIndex({ "username": 1 }, { unique: true });
db.admin_users.createIndex({ "email": 1 }, { unique: true });
db.admin_users.createIndex({ "role": 1 });

// Create service_disruptions collection with indexes
db.createCollection('service_disruptions');
db.service_disruptions.createIndex({ "routeId": 1 });
db.service_disruptions.createIndex({ "status": 1 });
db.service_disruptions.createIndex({ "severity": 1 });
db.service_disruptions.createIndex({ "startTime": 1, "endTime": 1 });

// Insert default admin user
db.admin_users.insertOne({
  username: "admin",
  email: "admin@transport.gov.na",
  password: "$2b$10$rQZ8kHWKtGY5uFJ4uFJ4uOJ4uFJ4uFJ4uFJ4uFJ4uFJ4uFJ4uFJ4u", // password: admin123
  firstName: "System",
  lastName: "Administrator",
  role: "ADMIN",
  permissions: ["ALL"],
  isActive: true,
  createdAt: new Date(),
  updatedAt: new Date()
});

print('Admin Service Database initialized with default admin user');

print('All databases initialized successfully!');
