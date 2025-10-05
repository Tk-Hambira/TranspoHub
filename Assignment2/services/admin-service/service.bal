import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerina/time;

// Admin Report Types
public type SalesReport record {|
    string reportId;
    time:Utc generatedTime;
    string period;
    int totalTickets;
    decimal totalRevenue;
    int completedPayments;
    int failedPayments;
    decimal averageTicketPrice;
    json routeBreakdown;
|};

public type ServiceDisruption record {|
    string id;
    string title;
    string description;
    string severity; // LOW, MEDIUM, HIGH, CRITICAL
    string[] affectedRoutes;
    time:Utc startTime;
    time:Utc? endTime;
    boolean active;
    time:Utc createdTime;
    string createdBy;
|};

public type DisruptionRequest record {|
    string title;
    string description;
    string severity;
    string[] affectedRoutes;
    time:Utc? startTime;
    time:Utc? endTime;
|};

public type SystemStats record {|
    int totalPassengers;
    int totalRoutes;
    int totalTrips;
    int totalTickets;
    int totalPayments;
    int totalNotifications;
    decimal totalRevenue;
    time:Utc lastUpdated;
|};

// In-memory storage for development
map<ServiceDisruption> disruptions = {};
map<SalesReport> reports = {};

// HTTP service configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /api/v1/admin on new http:Listener(8006) {

    // Health check endpoint
    resource function get health() returns json {
        return {
            "status": "UP",
            "service": "admin-service",
            "timestamp": time:utcNow()
        };
    }

    // Get system overview/dashboard
    resource function get dashboard() returns json {
        log:printInfo("Getting admin dashboard data");
        
        // In a real implementation, this would aggregate data from all services
        SystemStats stats = {
            totalPassengers: 150,
            totalRoutes: 12,
            totalTrips: 45,
            totalTickets: 320,
            totalPayments: 280,
            totalNotifications: 450,
            totalRevenue: 8750.50d,
            lastUpdated: time:utcNow()
        };

        return {
            "success": true,
            "message": "Dashboard data retrieved successfully",
            "data": {
                "stats": stats,
                "activeDisruptions": getActiveDisruptions(),
                "recentActivity": getRecentActivity()
            }
        };
    }

    // Generate sales report
    resource function post reports/sales(@http:Payload json reportRequest) returns http:Response|error {
        log:printInfo("Generating sales report");
        
        http:Response response = new;
        
        // Extract report parameters
        json|error periodResult = reportRequest.period;
        string period = periodResult is string ? periodResult : "daily";
        
        // Generate report
        string reportId = uuid:createType1AsString();
        time:Utc currentTime = time:utcNow();
        
        SalesReport report = {
            reportId: reportId,
            generatedTime: currentTime,
            period: period,
            totalTickets: 320,
            totalRevenue: 8750.50d,
            completedPayments: 280,
            failedPayments: 40,
            averageTicketPrice: 27.35d,
            routeBreakdown: {
                "route_001": {"tickets": 120, "revenue": 3000.00},
                "route_002": {"tickets": 95, "revenue": 2375.00},
                "route_003": {"tickets": 105, "revenue": 3375.50}
            }
        };
        
        reports[reportId] = report;
        
        response.statusCode = 201;
        response.setJsonPayload({
            "success": true,
            "message": "Sales report generated successfully",
            "data": report
        });
        return response;
    }

    // Get sales report by ID
    resource function get reports/sales/[string reportId]() returns http:Response|error {
        log:printInfo("Getting sales report: " + reportId);
        
        http:Response response = new;
        
        if !reports.hasKey(reportId) {
            response.statusCode = 404;
            response.setJsonPayload({
                "success": false,
                "message": "Sales report not found"
            });
            return response;
        }

        SalesReport report = reports.get(reportId);
        response.statusCode = 200;
        response.setJsonPayload({
            "success": true,
            "message": "Sales report retrieved successfully",
            "data": report
        });
        return response;
    }

    // Create service disruption
    resource function post disruptions(@http:Payload DisruptionRequest disruptionRequest) returns http:Response|error {
        log:printInfo("Creating service disruption: " + disruptionRequest.title);
        
        http:Response response = new;
        
        // Validate request
        if disruptionRequest.title.trim() == "" || disruptionRequest.description.trim() == "" {
            response.statusCode = 400;
            response.setJsonPayload({
                "success": false,
                "message": "Title and description are required"
            });
            return response;
        }

        // Create disruption
        string disruptionId = uuid:createType1AsString();
        time:Utc currentTime = time:utcNow();
        
        ServiceDisruption disruption = {
            id: disruptionId,
            title: disruptionRequest.title,
            description: disruptionRequest.description,
            severity: disruptionRequest.severity,
            affectedRoutes: disruptionRequest.affectedRoutes,
            startTime: disruptionRequest.startTime ?: currentTime,
            endTime: disruptionRequest.endTime,
            active: true,
            createdTime: currentTime,
            createdBy: "admin" // In real implementation, get from auth context
        };
        
        disruptions[disruptionId] = disruption;
        
        response.statusCode = 201;
        response.setJsonPayload({
            "success": true,
            "message": "Service disruption created successfully",
            "data": disruption
        });
        return response;
    }

    // Get all service disruptions
    resource function get disruptions(boolean? active = ()) returns json {
        log:printInfo("Getting service disruptions");
        
        ServiceDisruption[] filteredDisruptions = [];
        
        foreach ServiceDisruption disruption in disruptions {
            if active is boolean {
                if active == disruption.active {
                    filteredDisruptions.push(disruption);
                }
            } else {
                filteredDisruptions.push(disruption);
            }
        }

        return {
            "success": true,
            "message": "Service disruptions retrieved successfully",
            "data": filteredDisruptions
        };
    }

    // Update service disruption
    resource function put disruptions/[string disruptionId](@http:Payload json updateRequest) returns http:Response|error {
        log:printInfo("Updating service disruption: " + disruptionId);
        
        http:Response response = new;
        
        if !disruptions.hasKey(disruptionId) {
            response.statusCode = 404;
            response.setJsonPayload({
                "success": false,
                "message": "Service disruption not found"
            });
            return response;
        }

        ServiceDisruption disruption = disruptions.get(disruptionId);
        
        // Update fields if provided
        json|error activeResult = updateRequest.active;
        if activeResult is boolean {
            disruption.active = activeResult;
            if !activeResult {
                disruption.endTime = time:utcNow();
            }
        }
        
        disruptions[disruptionId] = disruption;
        
        response.statusCode = 200;
        response.setJsonPayload({
            "success": true,
            "message": "Service disruption updated successfully",
            "data": disruption
        });
        return response;
    }

    // Get system statistics
    resource function get stats() returns json {
        log:printInfo("Getting system statistics");
        
        SystemStats stats = {
            totalPassengers: 150,
            totalRoutes: 12,
            totalTrips: 45,
            totalTickets: 320,
            totalPayments: 280,
            totalNotifications: 450,
            totalRevenue: 8750.50d,
            lastUpdated: time:utcNow()
        };

        return {
            "success": true,
            "message": "System statistics retrieved successfully",
            "data": stats
        };
    }

    // Get all reports
    resource function get reports() returns json {
        SalesReport[] allReports = [];
        
        foreach SalesReport report in reports {
            allReports.push(report);
        }

        return {
            "success": true,
            "message": "All reports retrieved successfully",
            "data": allReports
        };
    }
}

// Helper function to get active disruptions
function getActiveDisruptions() returns ServiceDisruption[] {
    ServiceDisruption[] activeDisruptions = [];
    
    foreach ServiceDisruption disruption in disruptions {
        if disruption.active {
            activeDisruptions.push(disruption);
        }
    }
    
    return activeDisruptions;
}

// Helper function to get recent activity (mock data)
function getRecentActivity() returns json[] {
    return [
        {"type": "ticket_purchase", "timestamp": time:utcNow(), "description": "New ticket purchased for Route 001"},
        {"type": "payment_completed", "timestamp": time:utcNow(), "description": "Payment completed for Ticket #12345"},
        {"type": "trip_update", "timestamp": time:utcNow(), "description": "Trip TR001 delayed by 15 minutes"}
    ];
}
