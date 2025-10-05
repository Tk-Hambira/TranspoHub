import ballerina/http;
import ballerina/uuid;

// HTTP Listener 
listener http:Listener ticketingListener = new(8083);

// Mock Database
map<json> mockTicketDatabase = {};
json[] mockTickets = [];

// Types
type Ticket record {
    int id;
    int passenger_id;
    int transport_id;
    string ticket_type;
    decimal price;
    string status;
    string purchased_at;
};

type TicketRequest record {
    int passenger_id;
    int transport_id;
    string ticket_type;
    decimal price;
};

type TicketStatusUpdate record {
    int id;
    string status;
};

// Ticketing Service 
service /tickets on ticketingListener {

    // Create a ticket
    resource function post create(http:Request req) returns http:Response|error {
        json payload = check req.getJsonPayload();
        
        TicketRequest|error ticketReq = payload.cloneWithType(TicketRequest);
        if ticketReq is error {
            http:Response response = new;
            response.statusCode = 400;
            response.setJsonPayload({"status": "error", "message": "Invalid request format"});
            return response;
        }

        // Mock database insertion
        string ticketId = uuid:createType1AsString();
        int id = mockTickets.length() + 1;
        
        Ticket newTicket = {
            id: id,
            passenger_id: ticketReq.passenger_id,
            transport_id: ticketReq.transport_id,
            ticket_type: ticketReq.ticket_type,
            price: ticketReq.price,
            status: "CREATED",
            purchased_at: "2025-10-05T00:00:00Z"
        };
        
        mockTickets.push(newTicket.toJson());
        mockTicketDatabase[ticketId] = newTicket.toJson();
        
        // Mock Kafka event publishing (would send to ticket.events topic)
        // TODO: Implement actual Kafka producer when dependencies are available
        
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "message": "Ticket created",
            "ticket_id": id
        });
        return response;
    }

    // Get tickets for a passenger
    resource function get byPassenger/[int passengerId]() returns http:Response|error {
        json[] passengerTickets = [];
        
        foreach json ticket in mockTickets {
            if ticket.passenger_id == passengerId {
                passengerTickets.push(ticket);
            }
        }
        
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "tickets": passengerTickets
        });
        return response;
    }

    // Update ticket status (used internally when payment is confirmed or ticket validated)
    resource function put updateStatus(http:Request req) returns http:Response|error {
        json payload = check req.getJsonPayload();
        
        TicketStatusUpdate|error statusReq = payload.cloneWithType(TicketStatusUpdate);
        if statusReq is error {
            http:Response response = new;
            response.statusCode = 400;
            response.setJsonPayload({"status": "error", "message": "Invalid request format"});
            return response;
        }

        // Mock database update
        boolean found = false;
        foreach int i in 0 ..< mockTickets.length() {
            json ticket = mockTickets[i];
            if ticket.id == statusReq.id {
                map<json> updatedTicket = <map<json>>ticket.clone();
                updatedTicket["status"] = statusReq.status;
                mockTickets[i] = updatedTicket;
                found = true;
                break;
            }
        }
        
        http:Response response = new;
        if found {
            response.setJsonPayload({
                "status": "success", 
                "message": "Ticket status updated"
            });
        } else {
            response.statusCode = 404;
            response.setJsonPayload({
                "status": "error", 
                "message": "Ticket not found"
            });
        }
        
        return response;
    }

    // Validate ticket (for validators on vehicles)
    resource function post validate/[int ticketId](http:Request req) returns http:Response|error {
        // Find and validate ticket
        boolean found = false;
        string currentStatus = "";
        
        foreach int i in 0 ..< mockTickets.length() {
            json ticket = mockTickets[i];
            if ticket.id == ticketId {
                json statusValue = check ticket.status;
                currentStatus = statusValue.toString();
                if currentStatus == "PAID" {
                    map<json> updatedTicket = <map<json>>ticket.clone();
                    updatedTicket["status"] = "VALIDATED";
                    mockTickets[i] = updatedTicket;
                    found = true;
                } else {
                    found = true; // Found but not valid for validation
                }
                break;
            }
        }
        
        http:Response response = new;
        if !found {
            response.statusCode = 404;
            response.setJsonPayload({
                "status": "error", 
                "message": "Ticket not found"
            });
        } else if currentStatus != "PAID" {
            response.statusCode = 400;
            response.setJsonPayload({
                "status": "error", 
                "message": "Ticket is not valid for validation. Current status: " + currentStatus
            });
        } else {
            response.setJsonPayload({
                "status": "success", 
                "message": "Ticket validated successfully"
            });
        }
        
        return response;
    }

    // Get all tickets (admin function)
    resource function get all() returns http:Response|error {
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "tickets": mockTickets
        });
        return response;
    }
}
