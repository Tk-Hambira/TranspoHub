import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerina/time;
import ballerina/io;

// Type definitions
public type Route record {
    string id;
    string name;
    string routeType; // "BUS" | "TRAIN"
    string[] stops;
    decimal distance;
    int estimatedDuration; // in minutes
    decimal basePrice;
    boolean isActive;
    time:Utc createdAt;
    time:Utc updatedAt;
};

public type RouteRequest record {
    string name;
    string routeType;
    string[] stops;
    decimal distance;
    int estimatedDuration;
    decimal basePrice;
};

public type RouteResponse record {
    string id;
    string name;
    string routeType;
    string[] stops;
    decimal distance;
    int estimatedDuration;
    decimal basePrice;
    boolean isActive;
    time:Utc createdAt;
};

public type Trip record {
    string id;
    string routeId;
    time:Utc departureTime;
    time:Utc arrivalTime;
    int capacity;
    int currentOccupancy;
    string status; // "SCHEDULED" | "ACTIVE" | "COMPLETED" | "CANCELLED"
    string? vehicleId;
    string? driverId;
    time:Utc createdAt;
    time:Utc updatedAt;
};

public type TripRequest record {
    string routeId;
    time:Utc departureTime;
    time:Utc arrivalTime;
    int capacity;
    string? vehicleId;
    string? driverId;
};

public type TripResponse record {
    string id;
    string routeId;
    time:Utc departureTime;
    time:Utc arrivalTime;
    int capacity;
    int currentOccupancy;
    string status;
    string? vehicleId;
    string? driverId;
    time:Utc createdAt;
};

public type Schedule record {
    string id;
    string routeId;
    int dayOfWeek; // 0-6 (Sunday-Saturday)
    string[] departureTimes; // ["08:00", "10:00", "12:00"]
    boolean isActive;
    time:Utc effectiveFrom;
    time:Utc? effectiveTo;
    time:Utc createdAt;
};

// Configuration
configurable int servicePort = 8080;

// Storage configuration
configurable boolean persistToFile = true;
configurable string dataDir = "./data";

// In-memory storage with file persistence
map<Route> routes = {};
map<Trip> trips = {};
map<Schedule> schedules = {};

// Storage helper functions
function saveDataToFile() returns error? {
    if persistToFile {
        // Save routes
        Route[] routeArray = routes.toArray();
        json routeJson = routeArray.toJson();
        check io:fileWriteJson(dataDir + "/routes.json", routeJson);

        // Save trips
        Trip[] tripArray = trips.toArray();
        json tripJson = tripArray.toJson();
        check io:fileWriteJson(dataDir + "/trips.json", tripJson);
    }
}

function loadDataFromFile() returns error? {
    if persistToFile {
        // Load routes
        json|error routeContent = io:fileReadJson(dataDir + "/routes.json");
        if routeContent is json && routeContent is json[] {
            foreach json routeJson in routeContent {
                Route|error route = routeJson.cloneWithType(Route);
                if route is Route {
                    routes[route.id] = route;
                }
            }
        }

        // Load trips
        json|error tripContent = io:fileReadJson(dataDir + "/trips.json");
        if tripContent is json && tripContent is json[] {
            foreach json tripJson in tripContent {
                Trip|error trip = tripJson.cloneWithType(Trip);
                if trip is Trip {
                    trips[trip.id] = trip;
                }
            }
        }
    }
}

// Initialize with sample data
function initSampleData() {
    // Sample routes
    Route route1 = {
        id: uuid:createType1AsString(),
        name: "City Center - Airport",
        routeType: "BUS",
        stops: ["City Center", "Shopping Mall", "University", "Airport"],
        distance: 25.5,
        estimatedDuration: 45,
        basePrice: 15.50,
        isActive: true,
        createdAt: time:utcNow(),
        updatedAt: time:utcNow()
    };
    
    Route route2 = {
        id: uuid:createType1AsString(),
        name: "Windhoek Central - Katutura",
        routeType: "BUS",
        stops: ["Windhoek Central", "Khomasdal", "Goreangab", "Katutura"],
        distance: 18.2,
        estimatedDuration: 35,
        basePrice: 12.00,
        isActive: true,
        createdAt: time:utcNow(),
        updatedAt: time:utcNow()
    };
    
    routes[route1.id] = route1;
    routes[route2.id] = route2;
    
    log:printInfo("Sample routes initialized");
}

// Validation functions
function validateRouteRequest(RouteRequest routeRequest) returns string? {
    if routeRequest.name.trim().length() == 0 {
        return "Route name is required";
    }
    
    if routeRequest.routeType != "BUS" && routeRequest.routeType != "TRAIN" {
        return "Route type must be BUS or TRAIN";
    }
    
    if routeRequest.stops.length() < 2 {
        return "Route must have at least 2 stops";
    }
    
    if routeRequest.distance <= 0d {
        return "Distance must be greater than 0";
    }

    if routeRequest.estimatedDuration <= 0 {
        return "Estimated duration must be greater than 0";
    }

    if routeRequest.basePrice <= 0d {
        return "Base price must be greater than 0";
    }
    
    return ();
}

function validateTripRequest(TripRequest tripRequest) returns string? {
    if tripRequest.routeId.trim().length() == 0 {
        return "Route ID is required";
    }
    
    if !routes.hasKey(tripRequest.routeId) {
        return "Route not found";
    }
    
    if tripRequest.departureTime >= tripRequest.arrivalTime {
        return "Departure time must be before arrival time";
    }
    
    if tripRequest.capacity <= 0 {
        return "Capacity must be greater than 0";
    }
    
    return ();
}

// HTTP service
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"]
    }
}
service /api/v1/transport on new http:Listener(servicePort) {

    function init() returns error? {
        // Load existing data first
        error? loadResult = loadDataFromFile();
        if loadResult is error {
            log:printWarn("Could not load existing transport data: " + loadResult.message());
        }

        // Initialize sample data if no data exists
        if routes.length() == 0 {
            initSampleData();
            // Save the sample data
            error? saveResult = saveDataToFile();
            if saveResult is error {
                log:printWarn("Could not save sample data: " + saveResult.message());
            }
        }

        log:printInfo("Transport service initialized with " + routes.length().toString() + " routes");
    }

    // Health check endpoint
    resource function get health() returns json {
        return {
            "status": "UP",
            "service": "transport-service",
            "timestamp": time:utcNow(),
            "storage": persistToFile ? "file-persistent" : "in-memory",
            "routes": routes.length(),
            "trips": trips.length()
        };
    }

    // Get all routes
    resource function get routes(string? routeType = (), boolean? active = ()) returns json {
        log:printInfo("Getting all routes");
        
        RouteResponse[] routeResponses = [];
        
        foreach Route route in routes {
            // Apply filters
            if routeType is string && route.routeType != routeType {
                continue;
            }
            
            if active is boolean && route.isActive != active {
                continue;
            }
            
            RouteResponse routeResponse = {
                id: route.id,
                name: route.name,
                routeType: route.routeType,
                stops: route.stops,
                distance: route.distance,
                estimatedDuration: route.estimatedDuration,
                basePrice: route.basePrice,
                isActive: route.isActive,
                createdAt: route.createdAt
            };
            routeResponses.push(routeResponse);
        }

        return {
            "success": true,
            "data": routeResponses.toJson(),
            "count": routeResponses.length()
        };
    }

    // Create new route
    resource function post routes(@http:Payload RouteRequest routeRequest) returns http:Response|error {
        log:printInfo("Creating new route: " + routeRequest.name);
        
        http:Response response = new;
        
        // Validate input
        string? validationError = validateRouteRequest(routeRequest);
        if validationError is string {
            response.statusCode = 400;
            response.setJsonPayload({
                "success": false,
                "error": {
                    "code": "VALIDATION_ERROR",
                    "message": validationError
                }
            });
            return response;
        }

        // Create route record
        string routeId = uuid:createType1AsString();
        Route newRoute = {
            id: routeId,
            name: routeRequest.name,
            routeType: routeRequest.routeType,
            stops: routeRequest.stops,
            distance: routeRequest.distance,
            estimatedDuration: routeRequest.estimatedDuration,
            basePrice: routeRequest.basePrice,
            isActive: true,
            createdAt: time:utcNow(),
            updatedAt: time:utcNow()
        };

        // Store route
        routes[routeId] = newRoute;

        // Save to file
        error? saveResult = saveDataToFile();
        if saveResult is error {
            log:printWarn("Could not save route data: " + saveResult.message());
        }

        // Return success response
        RouteResponse routeResponse = {
            id: newRoute.id,
            name: newRoute.name,
            routeType: newRoute.routeType,
            stops: newRoute.stops,
            distance: newRoute.distance,
            estimatedDuration: newRoute.estimatedDuration,
            basePrice: newRoute.basePrice,
            isActive: newRoute.isActive,
            createdAt: newRoute.createdAt
        };

        response.statusCode = 201;
        response.setJsonPayload({
            "success": true,
            "data": routeResponse.toJson(),
            "message": "Route created successfully"
        });
        
        log:printInfo("Route created successfully: " + newRoute.id);
        return response;
    }

    // Get route by ID
    resource function get routes/[string routeId]() returns http:Response|error {
        log:printInfo("Getting route: " + routeId);
        
        http:Response response = new;
        
        if !routes.hasKey(routeId) {
            response.statusCode = 404;
            response.setJsonPayload({
                "success": false,
                "error": {
                    "code": "ROUTE_NOT_FOUND",
                    "message": "Route not found"
                }
            });
            return response;
        }

        Route route = routes.get(routeId);
        RouteResponse routeResponse = {
            id: route.id,
            name: route.name,
            routeType: route.routeType,
            stops: route.stops,
            distance: route.distance,
            estimatedDuration: route.estimatedDuration,
            basePrice: route.basePrice,
            isActive: route.isActive,
            createdAt: route.createdAt
        };

        response.statusCode = 200;
        response.setJsonPayload({
            "success": true,
            "data": routeResponse.toJson()
        });

        return response;
    }

    // Get trips for a route
    resource function get routes/[string routeId]/trips(string? status = ()) returns http:Response|error {
        log:printInfo("Getting trips for route: " + routeId);

        http:Response response = new;

        if !routes.hasKey(routeId) {
            response.statusCode = 404;
            response.setJsonPayload({
                "success": false,
                "error": {
                    "code": "ROUTE_NOT_FOUND",
                    "message": "Route not found"
                }
            });
            return response;
        }

        TripResponse[] tripResponses = [];

        foreach Trip trip in trips {
            if trip.routeId != routeId {
                continue;
            }

            // Apply status filter
            if status is string && trip.status != status {
                continue;
            }

            TripResponse tripResponse = {
                id: trip.id,
                routeId: trip.routeId,
                departureTime: trip.departureTime,
                arrivalTime: trip.arrivalTime,
                capacity: trip.capacity,
                currentOccupancy: trip.currentOccupancy,
                status: trip.status,
                vehicleId: trip.vehicleId,
                driverId: trip.driverId,
                createdAt: trip.createdAt
            };
            tripResponses.push(tripResponse);
        }

        response.statusCode = 200;
        response.setJsonPayload({
            "success": true,
            "data": tripResponses.toJson(),
            "count": tripResponses.length()
        });

        return response;
    }

    // Create new trip
    resource function post trips(@http:Payload TripRequest tripRequest) returns http:Response|error {
        log:printInfo("Creating new trip for route: " + tripRequest.routeId);

        http:Response response = new;

        // Validate input
        string? validationError = validateTripRequest(tripRequest);
        if validationError is string {
            response.statusCode = 400;
            response.setJsonPayload({
                "success": false,
                "error": {
                    "code": "VALIDATION_ERROR",
                    "message": validationError
                }
            });
            return response;
        }

        // Create trip record
        string tripId = uuid:createType1AsString();
        Trip newTrip = {
            id: tripId,
            routeId: tripRequest.routeId,
            departureTime: tripRequest.departureTime,
            arrivalTime: tripRequest.arrivalTime,
            capacity: tripRequest.capacity,
            currentOccupancy: 0,
            status: "SCHEDULED",
            vehicleId: tripRequest.vehicleId,
            driverId: tripRequest.driverId,
            createdAt: time:utcNow(),
            updatedAt: time:utcNow()
        };

        // Store trip
        trips[tripId] = newTrip;

        // Return success response
        TripResponse tripResponse = {
            id: newTrip.id,
            routeId: newTrip.routeId,
            departureTime: newTrip.departureTime,
            arrivalTime: newTrip.arrivalTime,
            capacity: newTrip.capacity,
            currentOccupancy: newTrip.currentOccupancy,
            status: newTrip.status,
            vehicleId: newTrip.vehicleId,
            driverId: newTrip.driverId,
            createdAt: newTrip.createdAt
        };

        response.statusCode = 201;
        response.setJsonPayload({
            "success": true,
            "data": tripResponse.toJson(),
            "message": "Trip created successfully"
        });

        log:printInfo("Trip created successfully: " + newTrip.id);
        return response;
    }

    // Get trip by ID
    resource function get trips/[string tripId]() returns http:Response|error {
        log:printInfo("Getting trip: " + tripId);

        http:Response response = new;

        if !trips.hasKey(tripId) {
            response.statusCode = 404;
            response.setJsonPayload({
                "success": false,
                "error": {
                    "code": "TRIP_NOT_FOUND",
                    "message": "Trip not found"
                }
            });
            return response;
        }

        Trip trip = trips.get(tripId);
        TripResponse tripResponse = {
            id: trip.id,
            routeId: trip.routeId,
            departureTime: trip.departureTime,
            arrivalTime: trip.arrivalTime,
            capacity: trip.capacity,
            currentOccupancy: trip.currentOccupancy,
            status: trip.status,
            vehicleId: trip.vehicleId,
            driverId: trip.driverId,
            createdAt: trip.createdAt
        };

        response.statusCode = 200;
        response.setJsonPayload({
            "success": true,
            "data": tripResponse.toJson()
        });

        return response;
    }

    // Update trip status
    resource function put trips/[string tripId]/status(@http:Payload json statusUpdate) returns http:Response|error {
        log:printInfo("Updating trip status: " + tripId);

        http:Response response = new;

        if !trips.hasKey(tripId) {
            response.statusCode = 404;
            response.setJsonPayload({
                "success": false,
                "error": {
                    "code": "TRIP_NOT_FOUND",
                    "message": "Trip not found"
                }
            });
            return response;
        }

        // Extract status from payload
        json|error statusValue = statusUpdate.status;
        if statusValue is error || statusValue is () {
            response.statusCode = 400;
            response.setJsonPayload({
                "success": false,
                "error": {
                    "code": "VALIDATION_ERROR",
                    "message": "Status is required"
                }
            });
            return response;
        }

        string newStatus = statusValue.toString();
        if newStatus != "SCHEDULED" && newStatus != "ACTIVE" && newStatus != "COMPLETED" && newStatus != "CANCELLED" {
            response.statusCode = 400;
            response.setJsonPayload({
                "success": false,
                "error": {
                    "code": "VALIDATION_ERROR",
                    "message": "Invalid status. Must be SCHEDULED, ACTIVE, COMPLETED, or CANCELLED"
                }
            });
            return response;
        }

        // Update trip status
        Trip trip = trips.get(tripId);
        trip.status = newStatus;
        trip.updatedAt = time:utcNow();
        trips[tripId] = trip;

        response.statusCode = 200;
        response.setJsonPayload({
            "success": true,
            "message": "Trip status updated successfully"
        });

        log:printInfo("Trip status updated: " + tripId + " -> " + newStatus);
        return response;
    }
}
