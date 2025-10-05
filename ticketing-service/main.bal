import ballerina/http;
import ballerina/io;

service /ticket on new http:Listener(8082) {

    resource function post create(http:Caller caller, http:Request req) returns error? {
        json ticket = check req.getJsonPayload();
        io:println("Ticket created: ", ticket.toJsonString());
        check caller->respond({message: "Ticket issued successfully!"});
    }
}
