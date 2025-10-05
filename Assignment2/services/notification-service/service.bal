import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerina/time;

// Notification Type Enum
public enum NotificationType {
    TRIP_UPDATE,
    TICKET_VALIDATION,
    PAYMENT_CONFIRMATION,
    SERVICE_DISRUPTION,
    SCHEDULE_CHANGE,
    BOOKING_CONFIRMATION
}

// Notification Status Enum
public enum NotificationStatus {
    PENDING,
    SENT,
    DELIVERED,
    FAILED,
    READ
}

// Notification Channel Enum
public enum NotificationChannel {
    EMAIL,
    SMS,
    PUSH,
    IN_APP
}

// Notification Type Definitions
public type Notification record {|
    string id;
    string recipientId;
    NotificationType 'type;
    NotificationChannel channel;
    NotificationStatus status;
    string title;
    string message;
    time:Utc createdTime;
    time:Utc? sentTime;
    time:Utc? deliveredTime;
    time:Utc? readTime;
    json metadata?;
|};

public type NotificationRequest record {|
    string recipientId;
    NotificationType 'type;
    NotificationChannel[] channels;
    string title;
    string message;
    json? metadata;
|};

public type NotificationResponse record {|
    boolean success;
    string message;
    Notification? data;
|};

public type NotificationListResponse record {|
    boolean success;
    string message;
    Notification[]? data;
|};

// In-memory storage for development
map<Notification> notifications = {};

// HTTP service configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /api/v1/notifications on new http:Listener(8005) {

    // Health check endpoint
    resource function get health() returns json {
        return {
            "status": "UP",
            "service": "notification-service",
            "timestamp": time:utcNow()
        };
    }

    // Send notification
    resource function post .(@http:Payload NotificationRequest notificationRequest) returns http:Response|error {
        log:printInfo("Sending notification to: " + notificationRequest.recipientId);
        
        http:Response response = new;
        
        // Validate request
        if notificationRequest.recipientId.trim() == "" || notificationRequest.title.trim() == "" || notificationRequest.message.trim() == "" {
            response.statusCode = 400;
            response.setJsonPayload({
                "success": false,
                "message": "Recipient ID, title, and message are required"
            });
            return response;
        }

        // Create notifications for each channel
        Notification[] createdNotifications = [];
        
        foreach NotificationChannel channel in notificationRequest.channels {
            string notificationId = uuid:createType1AsString();
            time:Utc currentTime = time:utcNow();

            Notification newNotification = {
                id: notificationId,
                recipientId: notificationRequest.recipientId,
                'type: notificationRequest.'type,
                channel: channel,
                status: PENDING,
                title: notificationRequest.title,
                message: notificationRequest.message,
                createdTime: currentTime,
                sentTime: (),
                deliveredTime: (),
                readTime: (),
                metadata: notificationRequest.metadata
            };

            // Simulate sending notification
            boolean sent = simulateNotificationSending(channel);
            if sent {
                newNotification.status = SENT;
                newNotification.sentTime = time:utcNow();
            } else {
                newNotification.status = FAILED;
            }

            notifications[notificationId] = newNotification;
            createdNotifications.push(newNotification);
        }

        NotificationResponse notificationResponse = {
            success: true,
            message: "Notifications processed successfully",
            data: createdNotifications.length() > 0 ? createdNotifications[0] : ()
        };

        response.statusCode = 201;
        response.setJsonPayload(notificationResponse.toJson());
        return response;
    }

    // Get notification by ID
    resource function get [string notificationId]() returns http:Response|error {
        log:printInfo("Getting notification: " + notificationId);
        
        http:Response response = new;
        
        if !notifications.hasKey(notificationId) {
            response.statusCode = 404;
            response.setJsonPayload({
                "success": false,
                "message": "Notification not found"
            });
            return response;
        }

        Notification notification = notifications.get(notificationId);
        NotificationResponse notificationResponse = {
            success: true,
            message: "Notification retrieved successfully",
            data: notification
        };

        response.statusCode = 200;
        response.setJsonPayload(notificationResponse.toJson());
        return response;
    }

    // Get notifications by recipient ID
    resource function get recipient/[string recipientId]() returns http:Response|error {
        log:printInfo("Getting notifications for recipient: " + recipientId);
        
        http:Response response = new;
        Notification[] recipientNotifications = [];

        foreach Notification notification in notifications {
            if notification.recipientId == recipientId {
                recipientNotifications.push(notification);
            }
        }

        NotificationListResponse notificationListResponse = {
            success: true,
            message: "Notifications retrieved successfully",
            data: recipientNotifications
        };

        response.statusCode = 200;
        response.setJsonPayload(notificationListResponse.toJson());
        return response;
    }

    // Mark notification as read
    resource function put [string notificationId]/read() returns http:Response|error {
        log:printInfo("Marking notification as read: " + notificationId);
        
        http:Response response = new;
        
        if !notifications.hasKey(notificationId) {
            response.statusCode = 404;
            response.setJsonPayload({
                "success": false,
                "message": "Notification not found"
            });
            return response;
        }

        Notification notification = notifications.get(notificationId);
        notification.status = READ;
        notification.readTime = time:utcNow();
        notifications[notificationId] = notification;

        NotificationResponse notificationResponse = {
            success: true,
            message: "Notification marked as read",
            data: notification
        };

        response.statusCode = 200;
        response.setJsonPayload(notificationResponse.toJson());
        return response;
    }

    // Get all notifications (for testing/admin)
    resource function get all() returns json {
        Notification[] allNotifications = [];
        
        foreach Notification notification in notifications {
            allNotifications.push(notification);
        }

        return {
            "success": true,
            "message": "All notifications retrieved successfully",
            "data": allNotifications
        };
    }

    // Get notification statistics
    resource function get stats() returns json {
        int totalNotifications = notifications.length();
        int sentNotifications = 0;
        int failedNotifications = 0;
        int readNotifications = 0;

        foreach Notification notification in notifications {
            if notification.status == SENT || notification.status == DELIVERED {
                sentNotifications += 1;
            } else if notification.status == FAILED {
                failedNotifications += 1;
            } else if notification.status == READ {
                readNotifications += 1;
            }
        }

        return {
            "success": true,
            "message": "Notification statistics retrieved successfully",
            "data": {
                "totalNotifications": totalNotifications,
                "sentNotifications": sentNotifications,
                "failedNotifications": failedNotifications,
                "readNotifications": readNotifications,
                "deliveryRate": totalNotifications > 0 ? (sentNotifications * 100) / totalNotifications : 0
            }
        };
    }

    // Send trip update notification
    resource function post trip\-update(@http:Payload json tripUpdate) returns http:Response|error {
        log:printInfo("Processing trip update notification");
        
        http:Response response = new;
        
        // Extract trip information
        json|error tripIdResult = tripUpdate.tripId;
        json|error messageResult = tripUpdate.message;

        string tripId = tripIdResult is string ? tripIdResult : "";
        string message = messageResult is string ? messageResult : "Trip update available";
        
        if tripId.trim() == "" {
            response.statusCode = 400;
            response.setJsonPayload({
                "success": false,
                "message": "Trip ID is required"
            });
            return response;
        }

        // In a real implementation, this would:
        // 1. Query database for passengers with tickets for this trip
        // 2. Send notifications to all affected passengers
        // For now, simulate with a test notification
        
        NotificationRequest notificationRequest = {
            recipientId: "all-passengers-on-trip-" + tripId,
            'type: TRIP_UPDATE,
            channels: [PUSH, SMS],
            title: "Trip Update",
            message: message,
            metadata: tripUpdate
        };

        // Create notification manually (simplified for demo)
        string notificationId = uuid:createType1AsString();
        time:Utc currentTime = time:utcNow();

        Notification newNotification = {
            id: notificationId,
            recipientId: notificationRequest.recipientId,
            'type: notificationRequest.'type,
            channel: PUSH,
            status: SENT,
            title: notificationRequest.title,
            message: notificationRequest.message,
            createdTime: currentTime,
            sentTime: currentTime,
            deliveredTime: (),
            readTime: (),
            metadata: notificationRequest.metadata
        };

        notifications[notificationId] = newNotification;

        NotificationResponse notificationResponse = {
            success: true,
            message: "Trip update notification sent successfully",
            data: newNotification
        };

        response.statusCode = 201;
        response.setJsonPayload(notificationResponse.toJson());
        return response;
    }
}

// Simulate notification sending with different success rates per channel
function simulateNotificationSending(NotificationChannel channel) returns boolean {
    // Simulate different success rates for different channels
    match channel {
        EMAIL => {
            return true; // 100% success rate for email
        }
        SMS => {
            return true; // 95% success rate for SMS (simplified to true for demo)
        }
        PUSH => {
            return true; // 90% success rate for push notifications
        }
        IN_APP => {
            return true; // 100% success rate for in-app notifications
        }
    }
    return false;
}
