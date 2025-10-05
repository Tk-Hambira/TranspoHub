import ballerina/http;
import ballerina/io;

service /notify on new http:Listener(8084) {

    resource function post send(http:Caller caller, http:Request req) returns error? {
        json notification = check req.getJsonPayload();
        io:println("Notification sent: ", notification.toJsonString());
        check caller->respond({message: "Notification sent successfully!"});
    }
}
