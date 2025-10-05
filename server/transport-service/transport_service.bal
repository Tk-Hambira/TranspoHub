import ballerina/http;
import ballerina/uuid;

// HTTP Listener 
listener http:Listener transportListener = new(8082);

// Mock Database 
map<json> mockTransportDatabase = {};
json[] mockRoutes = [];

//Types 
type Transport record {
    int id;
    string route_name;
    string origin;
    string destination;
    string departure_time;
    string arrival_time;
    string vehicle_type;
    string status;
    string last_updated;
};

type TransportRequest record {
    string route_name;
    string origin;
    string destination;
    string departure_time;
    string arrival_time;
    string vehicle_type;
};

type StatusUpdateRequest record {
    int id;
    string status;
};

// Transport Service 
service /transport on transportListener {

    // Create a new route/trip
    resource function post create(http:Request req) returns http:Response|error {
        json payload = check req.getJsonPayload();
        
        TransportRequest|error transportReq = payload.cloneWithType(TransportRequest);
        if transportReq is error {
            http:Response response = new;
            response.statusCode = 400;
            response.setJsonPayload({"status": "error", "message": "Invalid request format"});
            return response;
        }

        // Mock database insertion
        string transportId = uuid:createType1AsString();
        int id = mockRoutes.length() + 1;
        
        Transport newTransport = {
            id: id,
            route_name: transportReq.route_name,
            origin: transportReq.origin,
            destination: transportReq.destination,
            departure_time: transportReq.departure_time,
            arrival_time: transportReq.arrival_time,
            vehicle_type: transportReq.vehicle_type,
            status: "scheduled",
            last_updated: "2025-10-05T00:00:00Z"
        };
        
        mockRoutes.push(newTransport.toJson());
        mockTransportDatabase[transportId] = newTransport.toJson();
        
        // Mock Kafka event publishing (would send to schedule.updates topic)
        // TODO: Implement actual Kafka producer when dependencies are available
        
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "message": "Route created successfully",
            "id": id
        });
        return response;
    }

    // Update route/trip status (e.g., delayed, cancelled)
    resource function put updateStatus(http:Request req) returns http:Response|error {
        json payload = check req.getJsonPayload();
        
        StatusUpdateRequest|error statusReq = payload.cloneWithType(StatusUpdateRequest);
        if statusReq is error {
            http:Response response = new;
            response.statusCode = 400;
            response.setJsonPayload({"status": "error", "message": "Invalid request format"});
            return response;
        }

        // Mock database update
        boolean found = false;
        foreach int i in 0 ..< mockRoutes.length() {
            json route = mockRoutes[i];
            if route.id == statusReq.id {
                map<json> updatedRoute = <map<json>>route.clone();
                updatedRoute["status"] = statusReq.status;
                updatedRoute["last_updated"] = "2025-10-05T00:00:00Z";
                mockRoutes[i] = updatedRoute;
                found = true;
                break;
            }
        }
        
        http:Response response = new;
        if found {
            // Mock Kafka event publishing (would send to schedule.updates topic)
            // TODO: Implement actual Kafka producer when dependencies are available
            
            response.setJsonPayload({
                "status": "success", 
                "message": "Transport status updated"
            });
        } else {
            response.statusCode = 404;
            response.setJsonPayload({
                "status": "error", 
                "message": "Transport route not found"
            });
        }
        
        return response;
    }

    // Get all routes/trips
    resource function get all() returns http:Response|error {
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "routes": mockRoutes
        });
        return response;
    }

    // Get route by ID
    resource function get [int id]() returns http:Response|error {
        foreach json r in mockRoutes {
            if r.id == id {
                http:Response response = new;
                response.setJsonPayload({
                    "status": "success", 
                    "route": r
                });
                return response;
            }
        }
        
        http:Response response = new;
        response.statusCode = 404;
        response.setJsonPayload({
            "status": "error", 
            "message": "Route not found"
        });
        return response;
    }
}
