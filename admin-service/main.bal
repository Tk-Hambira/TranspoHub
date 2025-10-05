import ballerina/http;
import ballerina/io;

service /admin on new http:Listener(8085) {

    resource function get stats(http:Caller caller, http:Request req) returns error? {
        io:println("Admin requested system stats");
        check caller->respond({
            activeServices: ["passenger", "ticketing", "payment", "notification", "transport"],
            status: "All systems operational"
        });
    }
}
