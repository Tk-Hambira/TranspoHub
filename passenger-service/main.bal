import ballerina/http;
import ballerina/io;

service /passenger on new http:Listener(8081) {
    resource function post register(http:Caller caller, http:Request req) returns error? {
        json passenger = check req.getJsonPayload();
        io:println("Passenger registered: ", passenger.toJsonString());
        check caller->respond({message: "Passenger registered successfully!"});
    }
}
