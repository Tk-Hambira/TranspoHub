import ballerina/http;
import ballerina/io;

service /payment on new http:Listener(8083) {

    resource function post process(http:Caller caller, http:Request req) returns error? {
        json payment = check req.getJsonPayload();
        io:println("Payment processed: ", payment.toJsonString());
        check caller->respond({message: "Payment processed successfully!"});
    }
}
