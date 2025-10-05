import ballerina/http;
import ballerina/uuid;

// HTTP Listener 
listener http:Listener passengerListener = new(8081);

//  Database Client (Mock for now)
map<json> mockDatabase = {};

//  Types 
type Passenger record {
    int id;
    string full_name;
    string email;
    string password_hash;
    string? phone;
    string created_at;
};

type Ticket record {
    int id;
    string ticket_type;
    string status;
    string route_name;
    string origin;
    string destination;
    string departure_time;
    string arrival_time;
};

type PassengerRequest record {
    string full_name;
    string email;
    string password_hash;
    string? phone;
};

type LoginRequest record {
    string email;
    string password_hash;
};

//  Passenger Service 
service /passengers on passengerListener {

    // Passenger registration
    resource function post register(http:Request req) returns http:Response|error {
        json payload = check req.getJsonPayload();
        
        // Safe JSON extraction
        PassengerRequest|error passengerReq = payload.cloneWithType(PassengerRequest);
        if passengerReq is error {
            http:Response response = new;
            response.statusCode = 400;
            response.setJsonPayload({"status": "error", "message": "Invalid request format"});
            return response;
        }

        // Mock database insertion (replace with actual DB call)
        string passengerId = uuid:createType1AsString();
        Passenger newPassenger = {
            id: 1, // Mock ID
            full_name: passengerReq.full_name,
            email: passengerReq.email,
            password_hash: passengerReq.password_hash,
            phone: passengerReq.phone,
            created_at: "2025-10-05T00:00:00Z"
        };
        
        mockDatabase[passengerReq.email] = newPassenger.toJson();
        
        http:Response response = new;
        response.setJsonPayload({"status": "success", "message": "Passenger registered", "id": passengerId});
        return response;
    }

    // Passenger login
    resource function post login(http:Request req) returns http:Response|error {
        json payload = check req.getJsonPayload();
        
        LoginRequest|error loginReq = payload.cloneWithType(LoginRequest);
        if loginReq is error {
            http:Response response = new;
            response.statusCode = 400;
            response.setJsonPayload({"status": "error", "message": "Invalid request format"});
            return response;
        }

        // Mock authentication (replace with actual DB query)
        json? passengerData = mockDatabase[loginReq.email];
        
        http:Response response = new;
        if passengerData is json {
            Passenger|error passenger = passengerData.cloneWithType(Passenger);
            if passenger is Passenger && passenger.password_hash == loginReq.password_hash {
                response.setJsonPayload({
                    "status": "success", 
                    "message": "Login successful", 
                    "passenger": {
                        "id": passenger.id,
                        "full_name": passenger.full_name,
                        "email": passenger.email
                    }
                });
                return response;
            }
        }
        
        response.statusCode = 401;
        response.setJsonPayload({"status": "error", "message": "Invalid credentials"});
        return response;
    }

    // Get all tickets for a passenger
    resource function get tickets(http:Request req, int passengerId) returns http:Response|error {
        // Mock ticket data (replace with actual DB query)
        json[] tickets = [
            {
                id: 1,
                ticket_type: "single_ride",
                status: "PAID",
                route_name: "Route A",
                origin: "Windhoek Central",
                destination: "Katutura",
                departure_time: "2025-10-05 08:30:00",
                arrival_time: "2025-10-05 09:10:00"
            }
        ];
        
        http:Response response = new;
        response.setJsonPayload({"status": "success", "tickets": tickets});
        return response;
    }
}
