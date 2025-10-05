import ballerina/http;
import ballerina/io;

service /transport on new http:Listener(8086) {

    resource function post schedule(http:Caller caller, http:Request req) returns error? {
        json schedule = check req.getJsonPayload();
        io:println("New transport schedule received: ", schedule.toJsonString());
        check caller->respond({message: "Transport schedule created successfully!"});
    }
}
