import ballerina/http;
import ballerina/uuid;
import ballerina/random;

//  HTTP Listener 
listener http:Listener paymentListener = new(8084);

// Mock Database 
json[] mockPayments = [];

// Types 
type PaymentRequest record {
    int ticket_id;
    decimal amount;
    string method;
};

//  Payment Service
service /payments on paymentListener {

    // Simulate a payment for a ticket
    resource function post pay(http:Request req) returns http:Response|error {
        json payload = check req.getJsonPayload();
        
        PaymentRequest|error paymentReq = payload.cloneWithType(PaymentRequest);
        if paymentReq is error {
            http:Response response = new;
            response.statusCode = 400;
            response.setJsonPayload({"status": "error", "message": "Invalid request format"});
            return response;
        }

        // Mock payment processing
        int id = mockPayments.length() + 1;
        string transactionRef = "TXN_" + uuid:createType1AsString().substring(0, 8);
        
        // Simulate payment processing (90% success rate)
        int randomValue = check random:createIntInRange(1, 101);
        string paymentStatus = randomValue <= 90 ? "CONFIRMED" : "FAILED";
        
        json newPayment = {
            id: id,
            ticket_id: paymentReq.ticket_id,
            amount: paymentReq.amount,
            method: paymentReq.method,
            status: paymentStatus,
            transaction_ref: transactionRef,
            created_at: "2025-10-05T00:00:00Z"
        };
        
        mockPayments.push(newPayment);
        
        http:Response response = new;
        if paymentStatus == "CONFIRMED" {
            response.setJsonPayload({
                "status": "success",
                "message": "Payment processed successfully",
                "payment_status": paymentStatus,
                "transaction_ref": transactionRef,
                "payment_id": id
            });
        } else {
            response.statusCode = 400;
            response.setJsonPayload({
                "status": "error",
                "message": "Payment failed",
                "payment_status": paymentStatus,
                "transaction_ref": transactionRef,
                "payment_id": id
            });
        }
        
        return response;
    }

    // Get payment history for a ticket
    resource function get history/[int ticketId]() returns http:Response|error {
        json[] ticketPayments = [];
        
        foreach json payment in mockPayments {
            if payment.ticket_id == ticketId {
                ticketPayments.push(payment);
            }
        }
        
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "payments": ticketPayments
        });
        return response;
    }

    // Get all payments (admin function)
    resource function get all() returns http:Response|error {
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "payments": mockPayments
        });
        return response;
    }
}
