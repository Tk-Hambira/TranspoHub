import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerina/time;

// Ticket Status Enum
public enum TicketStatus {
    CREATED,
    PAID,
    VALIDATED,
    EXPIRED,
    CANCELLED
}

// Ticket Type Definitions
public type Ticket record {|
    string id;
    string passengerId;
    string routeId;
    string tripId;
    TicketStatus status;
    decimal price;
    time:Utc purchaseTime;
    time:Utc? validationTime;
    time:Utc? expiryTime;
    string seatNumber?;
    json metadata?;
|};

public type TicketRequest record {|
    string passengerId;
    string routeId;
    string tripId;
    string seatNumber?;
|};

public type TicketResponse record {|
    boolean success;
    string message;
    Ticket? data;
|};

public type TicketValidationRequest record {|
    string ticketId;
    string validatorId;
|};

public type TicketListResponse record {|
    boolean success;
    string message;
    Ticket[]? data;
|};

// In-memory storage for development
map<Ticket> tickets = {};

// HTTP service configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /api/v1/tickets on new http:Listener(8003) {

    // Health check endpoint
    resource function get health() returns json {
        return {
            "status": "UP",
            "service": "ticketing-service",
            "timestamp": time:utcNow()
        };
    }

    // Create new ticket
    resource function post .(@http:Payload TicketRequest ticketRequest) returns http:Response|error {
        log:printInfo("Creating new ticket for passenger: " + ticketRequest.passengerId);
        
        http:Response response = new;
        
        // Validate request
        if ticketRequest.passengerId.trim() == "" || ticketRequest.routeId.trim() == "" || ticketRequest.tripId.trim() == "" {
            response.statusCode = 400;
            response.setJsonPayload({
                "success": false,
                "message": "Passenger ID, Route ID, and Trip ID are required"
            });
            return response;
        }

        // Create new ticket
        string ticketId = uuid:createType1AsString();
        time:Utc currentTime = time:utcNow();
        time:Utc expiryTime = time:utcAddSeconds(currentTime, 86400); // 24 hours validity

        Ticket newTicket = {
            id: ticketId,
            passengerId: ticketRequest.passengerId,
            routeId: ticketRequest.routeId,
            tripId: ticketRequest.tripId,
            status: CREATED,
            price: 25.00d, // Default price
            purchaseTime: currentTime,
            validationTime: (),
            expiryTime: expiryTime,
            seatNumber: ticketRequest.seatNumber
        };

        tickets[ticketId] = newTicket;

        TicketResponse ticketResponse = {
            success: true,
            message: "Ticket created successfully",
            data: newTicket
        };

        response.statusCode = 201;
        response.setJsonPayload(ticketResponse.toJson());
        return response;
    }

    // Get ticket by ID
    resource function get [string ticketId]() returns http:Response|error {
        log:printInfo("Getting ticket: " + ticketId);
        
        http:Response response = new;
        
        if !tickets.hasKey(ticketId) {
            response.statusCode = 404;
            response.setJsonPayload({
                "success": false,
                "message": "Ticket not found"
            });
            return response;
        }

        Ticket ticket = tickets.get(ticketId);
        TicketResponse ticketResponse = {
            success: true,
            message: "Ticket retrieved successfully",
            data: ticket
        };

        response.statusCode = 200;
        response.setJsonPayload(ticketResponse.toJson());
        return response;
    }

    // Get tickets by passenger ID
    resource function get passenger/[string passengerId]() returns http:Response|error {
        log:printInfo("Getting tickets for passenger: " + passengerId);
        
        http:Response response = new;
        Ticket[] passengerTickets = [];

        foreach Ticket ticket in tickets {
            if ticket.passengerId == passengerId {
                passengerTickets.push(ticket);
            }
        }

        TicketListResponse ticketListResponse = {
            success: true,
            message: "Tickets retrieved successfully",
            data: passengerTickets
        };

        response.statusCode = 200;
        response.setJsonPayload(ticketListResponse.toJson());
        return response;
    }

    // Update ticket status to PAID
    resource function put [string ticketId]/pay() returns http:Response|error {
        log:printInfo("Processing payment for ticket: " + ticketId);
        
        http:Response response = new;
        
        if !tickets.hasKey(ticketId) {
            response.statusCode = 404;
            response.setJsonPayload({
                "success": false,
                "message": "Ticket not found"
            });
            return response;
        }

        Ticket ticket = tickets.get(ticketId);
        
        if ticket.status != CREATED {
            response.statusCode = 400;
            response.setJsonPayload({
                "success": false,
                "message": "Ticket cannot be paid. Current status: " + ticket.status.toString()
            });
            return response;
        }

        // Update ticket status
        ticket.status = PAID;
        tickets[ticketId] = ticket;

        TicketResponse ticketResponse = {
            success: true,
            message: "Ticket payment processed successfully",
            data: ticket
        };

        response.statusCode = 200;
        response.setJsonPayload(ticketResponse.toJson());
        return response;
    }

    // Validate ticket
    resource function put [string ticketId]/validate(@http:Payload TicketValidationRequest validationRequest) returns http:Response|error {
        log:printInfo("Validating ticket: " + ticketId);
        
        http:Response response = new;
        
        if !tickets.hasKey(ticketId) {
            response.statusCode = 404;
            response.setJsonPayload({
                "success": false,
                "message": "Ticket not found"
            });
            return response;
        }

        Ticket ticket = tickets.get(ticketId);
        
        if ticket.status != PAID {
            response.statusCode = 400;
            response.setJsonPayload({
                "success": false,
                "message": "Ticket cannot be validated. Current status: " + ticket.status.toString()
            });
            return response;
        }

        // Check if ticket is expired
        time:Utc currentTime = time:utcNow();
        time:Utc? expiryTime = ticket.expiryTime;
        if expiryTime is time:Utc {
            decimal timeDiff = time:utcDiffSeconds(expiryTime, currentTime);
            if timeDiff < 0d {
                ticket.status = EXPIRED;
                tickets[ticketId] = ticket;

                response.statusCode = 400;
                response.setJsonPayload({
                    "success": false,
                    "message": "Ticket has expired"
                });
                return response;
            }
        }

        // Validate ticket
        ticket.status = VALIDATED;
        ticket.validationTime = currentTime;
        tickets[ticketId] = ticket;

        TicketResponse ticketResponse = {
            success: true,
            message: "Ticket validated successfully",
            data: ticket
        };

        response.statusCode = 200;
        response.setJsonPayload(ticketResponse.toJson());
        return response;
    }

    // Get all tickets (for testing/admin)
    resource function get all() returns json {
        Ticket[] allTickets = [];
        
        foreach Ticket ticket in tickets {
            allTickets.push(ticket);
        }

        return {
            "success": true,
            "message": "All tickets retrieved successfully",
            "data": allTickets
        };
    }

    // Cancel ticket
    resource function put [string ticketId]/cancel() returns http:Response|error {
        log:printInfo("Cancelling ticket: " + ticketId);
        
        http:Response response = new;
        
        if !tickets.hasKey(ticketId) {
            response.statusCode = 404;
            response.setJsonPayload({
                "success": false,
                "message": "Ticket not found"
            });
            return response;
        }

        Ticket ticket = tickets.get(ticketId);
        
        if ticket.status == VALIDATED || ticket.status == EXPIRED {
            response.statusCode = 400;
            response.setJsonPayload({
                "success": false,
                "message": "Ticket cannot be cancelled. Current status: " + ticket.status.toString()
            });
            return response;
        }

        // Cancel ticket
        ticket.status = CANCELLED;
        tickets[ticketId] = ticket;

        TicketResponse ticketResponse = {
            success: true,
            message: "Ticket cancelled successfully",
            data: ticket
        };

        response.statusCode = 200;
        response.setJsonPayload(ticketResponse.toJson());
        return response;
    }
}
