import ballerina/http;

//  HTTP Listener 
listener http:Listener notificationListener = new(8085); // Changed port to avoid conflict

//  Mock Database 
json[] mockNotifications = [];

// Types 
type Notification record {
    int id;
    int? passenger_id;
    string message;
    boolean is_read;
    string created_at;
};

type NotificationRequest record {
    int? passenger_id;
    string message;
};

// -------------------- Notification Service --------------------
service /notifications on notificationListener {

    // Get notifications for a passenger
    resource function get passenger/[int passengerId]() returns http:Response|error {
        json[] passengerNotifications = [];
        
        foreach json notification in mockNotifications {
            if notification.passenger_id == passengerId {
                passengerNotifications.push(notification);
            }
        }
        
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "notifications": passengerNotifications
        });
        return response;
    }

    // Create a notification (admin/system function)
    resource function post create(http:Request req) returns http:Response|error {
        json payload = check req.getJsonPayload();
        
        NotificationRequest|error notificationReq = payload.cloneWithType(NotificationRequest);
        if notificationReq is error {
            http:Response response = new;
            response.statusCode = 400;
            response.setJsonPayload({"status": "error", "message": "Invalid request format"});
            return response;
        }

        // Mock notification creation
        int id = mockNotifications.length() + 1;
        
        json newNotification = {
            id: id,
            passenger_id: notificationReq.passenger_id,
            message: notificationReq.message,
            is_read: false,
            created_at: "2025-10-05T00:00:00Z"
        };
        
        mockNotifications.push(newNotification);
        
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "message": "Notification created",
            "notification_id": id
        });
        return response;
    }

    // Mark notification as read
    resource function put markRead/[int notificationId]() returns http:Response|error {
        boolean found = false;
        
        foreach int i in 0 ..< mockNotifications.length() {
            json notification = mockNotifications[i];
            if notification.id == notificationId {
                map<json> updatedNotification = <map<json>>notification.clone();
                updatedNotification["is_read"] = true;
                mockNotifications[i] = updatedNotification;
                found = true;
                break;
            }
        }
        
        http:Response response = new;
        if found {
            response.setJsonPayload({
                "status": "success", 
                "message": "Notification marked as read"
            });
        } else {
            response.statusCode = 404;
            response.setJsonPayload({
                "status": "error", 
                "message": "Notification not found"
            });
        }
        
        return response;
    }

    // Get all notifications (admin function)
    resource function get all() returns http:Response|error {
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "notifications": mockNotifications
        });
        return response;
    }

    // Broadcast notification to all passengers
    resource function post broadcast(http:Request req) returns http:Response|error {
        json payload = check req.getJsonPayload();
        
        string|error message = payload.message.ensureType(string);
        if message is error {
            http:Response response = new;
            response.statusCode = 400;
            response.setJsonPayload({"status": "error", "message": "Message is required"});
            return response;
        }

        // Create notification for all passengers (broadcast)
        int id = mockNotifications.length() + 1;
        
        json broadcastNotification = {
            id: id,
            passenger_id: (), // null means broadcast to all
            message: message,
            is_read: false,
            created_at: "2025-10-05T00:00:00Z"
        };
        
        mockNotifications.push(broadcastNotification);
        
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "message": "Broadcast notification created",
            "notification_id": id
        });
        return response;
    }
}
