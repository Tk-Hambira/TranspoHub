import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerina/time;
import ballerina/random;

// Payment Status Enum
public enum PaymentStatus {
    PENDING,
    PROCESSING,
    COMPLETED,
    FAILED,
    REFUNDED,
    CANCELLED
}

// Payment Method Enum
public enum PaymentMethod {
    CREDIT_CARD,
    DEBIT_CARD,
    MOBILE_MONEY,
    BANK_TRANSFER,
    CASH
}

// Payment Type Definitions
public type Payment record {|
    string id;
    string ticketId;
    string passengerId;
    decimal amount;
    PaymentMethod method;
    PaymentStatus status;
    time:Utc createdTime;
    time:Utc? processedTime;
    string? transactionId;
    string? failureReason;
    json metadata?;
|};

public type PaymentRequest record {|
    string ticketId;
    string passengerId;
    decimal amount;
    PaymentMethod method;
    json? paymentDetails;
|};

public type PaymentResponse record {|
    boolean success;
    string message;
    Payment? data;
|};

public type PaymentListResponse record {|
    boolean success;
    string message;
    Payment[]? data;
|};

// In-memory storage for development
map<Payment> payments = {};

// HTTP service configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /api/v1/payments on new http:Listener(8004) {

    // Health check endpoint
    resource function get health() returns json {
        return {
            "status": "UP",
            "service": "payment-service",
            "timestamp": time:utcNow()
        };
    }

    // Process payment
    resource function post .(@http:Payload PaymentRequest paymentRequest) returns http:Response|error {
        log:printInfo("Processing payment for ticket: " + paymentRequest.ticketId);
        
        http:Response response = new;
        
        // Validate request
        if paymentRequest.ticketId.trim() == "" || paymentRequest.passengerId.trim() == "" || paymentRequest.amount <= 0d {
            response.statusCode = 400;
            response.setJsonPayload({
                "success": false,
                "message": "Ticket ID, Passenger ID, and valid amount are required"
            });
            return response;
        }

        // Create new payment
        string paymentId = uuid:createType1AsString();
        time:Utc currentTime = time:utcNow();

        Payment newPayment = {
            id: paymentId,
            ticketId: paymentRequest.ticketId,
            passengerId: paymentRequest.passengerId,
            amount: paymentRequest.amount,
            method: paymentRequest.method,
            status: PENDING,
            createdTime: currentTime,
            processedTime: (),
            transactionId: (),
            failureReason: (),
            metadata: paymentRequest.paymentDetails
        };

        payments[paymentId] = newPayment;

        // Simulate payment processing
        PaymentStatus finalStatus = simulatePaymentProcessing();
        newPayment.status = finalStatus;
        newPayment.processedTime = time:utcNow();
        
        if finalStatus == COMPLETED {
            string fullUuid = uuid:createType1AsString();
            newPayment.transactionId = "TXN_" + fullUuid.substring(0, 8);
        } else if finalStatus == FAILED {
            newPayment.failureReason = "Insufficient funds or card declined";
        }

        payments[paymentId] = newPayment;

        PaymentResponse paymentResponse = {
            success: finalStatus == COMPLETED,
            message: finalStatus == COMPLETED ? "Payment processed successfully" : "Payment failed",
            data: newPayment
        };

        response.statusCode = finalStatus == COMPLETED ? 201 : 400;
        response.setJsonPayload(paymentResponse.toJson());
        return response;
    }

    // Get payment by ID
    resource function get [string paymentId]() returns http:Response|error {
        log:printInfo("Getting payment: " + paymentId);
        
        http:Response response = new;
        
        if !payments.hasKey(paymentId) {
            response.statusCode = 404;
            response.setJsonPayload({
                "success": false,
                "message": "Payment not found"
            });
            return response;
        }

        Payment payment = payments.get(paymentId);
        PaymentResponse paymentResponse = {
            success: true,
            message: "Payment retrieved successfully",
            data: payment
        };

        response.statusCode = 200;
        response.setJsonPayload(paymentResponse.toJson());
        return response;
    }

    // Get payments by passenger ID
    resource function get passenger/[string passengerId]() returns http:Response|error {
        log:printInfo("Getting payments for passenger: " + passengerId);
        
        http:Response response = new;
        Payment[] passengerPayments = [];

        foreach Payment payment in payments {
            if payment.passengerId == passengerId {
                passengerPayments.push(payment);
            }
        }

        PaymentListResponse paymentListResponse = {
            success: true,
            message: "Payments retrieved successfully",
            data: passengerPayments
        };

        response.statusCode = 200;
        response.setJsonPayload(paymentListResponse.toJson());
        return response;
    }

    // Get payments by ticket ID
    resource function get ticket/[string ticketId]() returns http:Response|error {
        log:printInfo("Getting payments for ticket: " + ticketId);
        
        http:Response response = new;
        Payment[] ticketPayments = [];

        foreach Payment payment in payments {
            if payment.ticketId == ticketId {
                ticketPayments.push(payment);
            }
        }

        PaymentListResponse paymentListResponse = {
            success: true,
            message: "Payments retrieved successfully",
            data: ticketPayments
        };

        response.statusCode = 200;
        response.setJsonPayload(paymentListResponse.toJson());
        return response;
    }

    // Refund payment
    resource function put [string paymentId]/refund() returns http:Response|error {
        log:printInfo("Processing refund for payment: " + paymentId);
        
        http:Response response = new;
        
        if !payments.hasKey(paymentId) {
            response.statusCode = 404;
            response.setJsonPayload({
                "success": false,
                "message": "Payment not found"
            });
            return response;
        }

        Payment payment = payments.get(paymentId);
        
        if payment.status != COMPLETED {
            response.statusCode = 400;
            response.setJsonPayload({
                "success": false,
                "message": "Only completed payments can be refunded. Current status: " + payment.status.toString()
            });
            return response;
        }

        // Process refund
        payment.status = REFUNDED;
        payment.processedTime = time:utcNow();
        payments[paymentId] = payment;

        PaymentResponse paymentResponse = {
            success: true,
            message: "Payment refunded successfully",
            data: payment
        };

        response.statusCode = 200;
        response.setJsonPayload(paymentResponse.toJson());
        return response;
    }

    // Get all payments (for testing/admin)
    resource function get all() returns json {
        Payment[] allPayments = [];
        
        foreach Payment payment in payments {
            allPayments.push(payment);
        }

        return {
            "success": true,
            "message": "All payments retrieved successfully",
            "data": allPayments
        };
    }

    // Get payment statistics
    resource function get stats() returns json {
        int totalPayments = payments.length();
        int completedPayments = 0;
        int failedPayments = 0;
        decimal totalAmount = 0d;

        foreach Payment payment in payments {
            if payment.status == COMPLETED {
                completedPayments += 1;
                totalAmount += payment.amount;
            } else if payment.status == FAILED {
                failedPayments += 1;
            }
        }

        return {
            "success": true,
            "message": "Payment statistics retrieved successfully",
            "data": {
                "totalPayments": totalPayments,
                "completedPayments": completedPayments,
                "failedPayments": failedPayments,
                "totalAmount": totalAmount,
                "successRate": totalPayments > 0 ? (completedPayments * 100) / totalPayments : 0
            }
        };
    }
}

// Simulate payment processing with random success/failure
function simulatePaymentProcessing() returns PaymentStatus {
    // Simulate processing delay
    // In real implementation, this would be async
    
    // 80% success rate for simulation
    float randomValue = random:createDecimal();
    if randomValue < 0.8 {
        return COMPLETED;
    } else {
        return FAILED;
    }
}
